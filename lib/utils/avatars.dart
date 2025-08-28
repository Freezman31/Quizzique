enum Avatar { bear, cow, dog, fox, lion, panda, pig, rabbit, tiger }

String avatarToFile({required Avatar avatar}) {
  switch (avatar) {
    case Avatar.bear:
      return 'assets/avatars/bear.png';
    case Avatar.cow:
      return 'assets/avatars/cow.png';
    case Avatar.dog:
      return 'assets/avatars/dog.png';
    case Avatar.fox:
      return 'assets/avatars/fox.png';
    case Avatar.lion:
      return 'assets/avatars/lion.png';
    case Avatar.panda:
      return 'assets/avatars/panda.png';
    case Avatar.pig:
      return 'assets/avatars/pig.png';
    case Avatar.rabbit:
      return 'assets/avatars/rabbit.png';
    case Avatar.tiger:
      return 'assets/avatars/tiger.png';
  }
}
