import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onSchedule } from "firebase-functions/v2/scheduler";

initializeApp();

const FUNCTION_REGION = "asia-northeast3";
const DEFAULT_OPTIONS = {
  region: FUNCTION_REGION,
};

export const sendPostNotification = onRequest(
  { ...DEFAULT_OPTIONS, timeoutSeconds: 120 },
  async (request, response) => {
    const hobby = request.body.hobby;

    if (!hobby) {
      response.status(400).send("잘못된 요청: 요청 본문에 'hobby' 필드가 누락되었습니다.");
      return;
    }

    const notification = {
      title: "새로운 Post 추가", // 알림 내용은 이미 한글
      body: "당신의 취미에 새로운 글이 추가되었습니다", // 알림 내용은 이미 한글
    };

    try {
      const db = getFirestore();
      const usersRef = db.collection("users");
      const querySnapshot = await usersRef
        .where("hobby", "==", hobby)
        .where("hobbyNoti", "==", true)
        .get();

      const messages = [];
      const tokens = [];
      querySnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fcm && typeof data.fcm === 'string' && data.fcm.length > 0 && data.hobbyNoti === true) {
          tokens.push(data.fcm);
        } else if (data.fcm && data.hobbyNoti === true) {
            logger.warn(`Invalid FCM token found for user ${doc.id}: ${data.fcm}`);
        }
      });

      if (tokens.length > 0) {
        const messaging = getMessaging();
        tokens.forEach((token) => {
          messages.push({
            token: token,
            notification: notification,
          });
        });

        const batchResponse = await messaging.sendEach(messages);
        logger.info(`Successfully sent ${batchResponse.successCount} messages`); // 성공 카운트 로깅

        if (batchResponse.failureCount > 0) {
          logger.warn(`Failed to send ${batchResponse.failureCount} messages`); // 실패 카운트 로깅
          const failedTokens = [];
          batchResponse.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errorCode = resp.error?.code;
              const errorMessage = resp.error?.message;
              logger.error(`Failed to send message to token ${messages[idx].token}: ${errorCode} - ${errorMessage}`);
              if (
                errorCode === "messaging/invalid-registration-token" ||
                errorCode === "messaging/registration-token-not-registered" ||
                (errorCode === "messaging/invalid-argument" &&
                  errorMessage?.includes("valid FCM registration token")) // 에러 메시지 포함 여부 확인
              ) {
                failedTokens.push(messages[idx].token);
                logger.warn(`잘못된 토큰 제거 예정: ${messages[idx].token}`); // 로그 메시지 한글화 (선택 사항)
              }
            }
          });
        }
        response.status(200).send(`알림 전송 완료: ${batchResponse.successCount}건 성공, ${batchResponse.failureCount}건 실패`);
      } else {
        logger.info("해당 취미를 가진 사용자가 없거나 알림 수신을 설정한 사용자가 없습니다."); // 로그 메시지 한글화
        response.status(200).send("알림을 보낼 대상 사용자가 없습니다.");
      }
    } catch (error) {
      logger.error("알림 전송 중 오류 발생:", error); // 에러 로깅 강화
      response.status(500).send("내부 서버 오류: 메시지를 보낼 수 없습니다.");
    }
  }
);

export const commentPushNotification = onDocumentCreated(
  {
    ...DEFAULT_OPTIONS,
    document: "posts/{postId}/comments/{commentId}",
  },
  async (event) => {
    const params = event.params;
    const postId = params.postId;
    const commentData = event.data?.data();

    if (!commentData) {
        logger.error("댓글 데이터가 없습니다.");
        return null;
    }

    try {
      const db = getFirestore();
      const postRef = db.collection("posts").doc(postId);
      const postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        logger.error(`ID가 ${postId}인 게시글 문서를 찾을 수 없습니다.`);
        return null;
      }

      const post = postSnapshot.data();
      if (!post?.user || !post?.content) {
        logger.error(`게시글 ${postId}에 'user' 또는 'content' 필드가 누락되었습니다.`);
        return null;
      }
      const postAuthorId = post.user;
      const postContentSnippet = post.content.substring(0, 50) + (post.content.length > 50 ? "..." : ""); // 미리보기 길이 조정 (50자)

      const userRef = db.collection("users").doc(postAuthorId);
      const userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        logger.warn(`게시글 작성자 ID ${postAuthorId} 사용자를 찾을 수 없습니다.`);
        return null;
      }

      const userData = userSnapshot.data();
      if (userData?.commentNoti === true && userData?.fcm) {
        const userToken = userData.fcm;

        const notification = {
          title: "새로운 댓글 알림",
          body: `회원님의 게시글 "${postContentSnippet}"에 새로운 댓글이 달렸습니다.`, // 댓글 내용 일부 포함 가능 (예: commentData.content 사용)
        };

        const message = {
          token: userToken,
          notification: notification,
        };

        const messaging = getMessaging();
        try {
          const response = await messaging.send(message);
          logger.info(`댓글 알림 성공적으로 전송됨 (사용자 ID: ${postAuthorId}, 메시지 ID: ${response})`);
        } catch (error) { // error 타입 명시
          logger.error(`사용자 ID ${postAuthorId}에게 댓글 알림 전송 실패:`, error);

          const errorCode = error.code;
          const errorMessage = error.message;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered" ||
            (errorCode === "messaging/invalid-argument" &&
              errorMessage?.includes("valid FCM registration token"))
          ) {
            logger.warn(`잘못된 토큰 제거 예정 (사용자 ID: ${postAuthorId}): ${userToken}`);
            await userRef.update({ fcm: null });
          }
        }
      } else {
        if (userData?.commentNoti !== true) {
            logger.info(`사용자 ID ${postAuthorId}가 댓글 알림 수신을 설정하지 않았습니다.`);
        }
        if (!userData?.fcm) {
            logger.info(`사용자 ID ${postAuthorId}의 FCM 토큰이 없습니다.`);
        }
      }
    } catch (error) {
      logger.error("댓글 알림 처리 중 오류 발생:", error);
    }
    return null;
  }
);