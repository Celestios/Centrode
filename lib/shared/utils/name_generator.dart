import 'dart:math';

class NameGenerator {
  static final _random = Random();

  static const _adjectives = [
    'happy', 'clever', 'brave', 'calm', 'eager',
    'fair', 'gentle', 'honest', 'jolly', 'kind',
    'lively', 'merry', 'nice', 'proud', 'silly',
    'witty', 'young', 'bold', 'bright', 'chill',
    'cool', 'dope', 'epic', 'fast', 'free',
    'golden', 'keen', 'lit', 'mystic', 'noble',
    'prime', 'rapid', 'sharp', 'swift', 'vivid',
    'wild', 'zen', 'atomic', 'basic', 'cosmic',
    'digital', 'electric', 'fluid', 'global', 'hyper',
    'ionic', 'lunar', 'macro', 'nano', 'optic',
    'prism', 'quantum', 'radar', 'solar', 'turbo',
    'ultra', 'vapor', 'wave', 'zero', 'amber',
    'azure', 'coral', 'ivory', 'jade', 'maple',
    'ocean', 'ruby', 'sage', 'teal', 'coral',
  ];

  static const _nouns = [
    'fox', 'bear', 'wolf', 'hawk', 'lynx',
    'owl', 'stag', 'deer', 'hare', 'crow',
    'dove', 'finch', 'wren', 'swift', 'robin',
    'lion', 'tiger', 'puma', 'panda', 'koala',
    'otter', 'whale', 'eagle', 'crane', 'heron',
    'pike', 'bass', 'trout', 'salmon', 'shark',
    'whale', 'coral', 'pearl', 'shell', 'wave',
    'star', 'moon', 'sun', 'comet', 'nova',
    'mars', 'venus', 'pluto', 'neptune', 'jupiter',
    'saturn', 'uranus', 'mercury', 'earth', 'sun',
    'bolt', 'flash', 'spark', 'surge', 'blaze',
    'frost', 'storm', 'thunder', 'lightning', 'cloud',
    'rain', 'snow', 'wind', 'fire', 'earth',
    'metal', 'steel', 'iron', 'gold', 'silver',
    'bronze', 'copper', 'chrome', 'titanium', 'carbon',
    'pixel', 'byte', 'bit', 'code', 'data',
    'node', 'link', 'mesh', 'grid', 'sync',
    'flux', 'core', 'hub', 'net', 'web',
    'mind', 'brain', 'heart', 'soul', 'spirit',
  ];

  static String generate() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    return '$adjective-$noun';
  }

  static String generateMultiple(int count) {
    return generate();
  }
}
