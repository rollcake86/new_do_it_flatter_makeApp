void main() {
  Car bmw = Car(320, 100000, 'BMW');
  Car toyota = Car(250, 70000, 'TOYOTA');
  Car ford = Car(200, 80000, 'FORD');
  print(bmw.price); // 100000 출력
  bmw.saleCar(); // bmw.price는 변경되지 않습니다.
  bmw.saleCar();
  print(bmw.saleCar()); // 90000 출력
}
  class Car {
  int maxSpeed;
  double price;
  String name;
    Car(this.maxSpeed, this.price, this.name);
    double saleCar() {
       price = price * 0.9;
    return price;
    }
  }
