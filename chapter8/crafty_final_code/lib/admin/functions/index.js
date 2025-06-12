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

export const craftySendPostNotification = onRequest(
    { timeoutSeconds: 120, region: "asia-northeast3" }, // 옵션을 첫 번째 인수로 전달, 필요에 따라 region 추가/변경
    async (req, res) => {
      // POST 요청 본문 확인
      if (req.method !== "POST") {
          res.status(405).send("Method Not Allowed");
          return;
      }
      const messages = [];
      const linkId = req.body.link;
      const title = req.body.title;

      // linkId 와 title 이 존재하는지 확인
      if (!linkId || !title) {
          res.status(400).send("Missing link or title in request body");
          return;
      }
        const notification = {
            title: "Crafty",
            body: title,
        };

      try {
        const querySnapshot = await getFirestore().collection("craftyusers").get();
        const tokens = [];
        querySnapshot.forEach((doc) => {
          const data = doc.data();
          // data.noti 와 data.fcm 이 모두 유효한지 확인
          if (data.noti && data.fcm && typeof data.fcm === 'string' && data.fcm.length > 0) {
            tokens.push(data.fcm);
          } else {
              logger.warn("Skipping user due to missing or invalid noti/fcm field:", doc.id, data);
          }
        });

        logger.info(`Found ${tokens.length} tokens to send notifications.`);

        if (tokens.length > 0) {
          // FCM은 최대 1000개의 토큰으로 메시지를 보낼 수 있습니다. (v1 코드와 동일)
          const chunks = [];
          const chunkSize = 1000;
          for (let i = 0; i < tokens.length; i += chunkSize) {
            chunks.push(tokens.slice(i, i + chunkSize));
          }

          const sendPromises = chunks.map(async (chunk) => {
            try {
        const messaging = getMessaging();
        tokens.forEach((token) => {
          messages.push({
            token: token,
            notification: notification,
            data : { link : linkId }
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
        return batchResponse
            } catch (error) {
                logger.error("Error sending multicast message chunk:", error);
                // 개별 청크 실패 시에도 계속 진행하도록 null 또는 에러 객체 반환 가능
                return { successCount: 0, failureCount: chunk.length, error: error };
            }
          });

          // 모든 청크 전송 시도 완료 기다리기
          const results = await Promise.all(sendPromises);

          // 전체 성공/실패 집계 (선택 사항)
          let totalSuccess = 0;
          let totalFailure = 0;
          results.forEach(result => {
              if (result && result.successCount !== undefined) {
                  totalSuccess += result.successCount;
                  totalFailure += result.failureCount;
              } else if (result && result.error) {

              }
          });


          logger.info(`Overall: Successfully sent ${totalSuccess} messages, failed ${totalFailure} messages.`);
          res.status(200).send(`Successfully sent ${totalSuccess} messages, failed ${totalFailure}.`);

        } else {
          logger.info("No valid tokens found for notification.");
          res.status(200).send("No valid tokens found."); // 토큰이 없는 것은 서버 오류가 아님
        }
      } catch (error) {
        logger.error("Error processing sendPostNotification request:", error);
        res.status(500).send("Internal Server Error: " + error.message);
      }
    }
);

export const deleteOldData = onSchedule(
    {
      schedule: "every day 00:00",
      timeZone: "Asia/Seoul", // 시간대 설정 (중요)
      timeoutSeconds: 540, // 기본값은 60초, 긴 작업 시 늘리기 (최대 540초)
      memory: "256MiB", // 필요에 따라 메모리 조정
      region: "asia-northeast3" // 함수 실행 지역 설정
    },
    async (event) => {
      logger.info(`Running scheduled job to delete old data at ${event.scheduleTime} (timezone: ${event.timeZone})`);

      const db = getFirestore;
      // 30일 이전의 타임스탬프 계산
      const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;

      try {
        // 'messages' 컬렉션에서 'timestamp' 필드가 30일 이전인 문서 쿼리
        const snapshot = await db.collection("messages")
            .where("timestamp", "<", new Date(thirtyDaysAgo)) // Firestore 타임스탬프 객체와 비교 시 Date 객체 사용 권장
            .limit(500) // Firestore 일괄 삭제는 500개 제한이 있으므로 반복 실행 필요
            .get();

        if (snapshot.empty) {
          logger.info("No old documents found to delete.");
          return; // 삭제할 문서 없으면 종료
        }

        // Firestore 일괄 쓰기 (Batch) 생성
        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref); // 각 문서 삭제 작업을 배치에 추가
        });

        // 배치 작업 실행
        await batch.commit();
        logger.info(`Successfully deleted ${snapshot.size} old documents.`);

        // 아직 삭제할 문서가 더 있을 수 있으므로, 함수가 다시 실행될 수 있도록 처리
        if (snapshot.size === 500) {
            logger.info("There might be more documents to delete in the next run.");
        }

      } catch (error) {
        logger.error("Error deleting old data:", error);
      }
    }
);