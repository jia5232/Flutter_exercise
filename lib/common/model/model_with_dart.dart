//해당 모델에 아이디가 있다는 것을 보장하기 위해 사용하는 인터페이스의 역할
abstract class IModelWithId {
  final String id;

  IModelWithId({
    required this.id,
  });
}
