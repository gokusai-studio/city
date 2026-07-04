import 'dart:math';
import '../../data/models/tile.dart';

/// 市民エージェントに「顔が見える街」の演出として、名前・年齢・職業・
/// 短い生活ストーリーを付与するジェネレーター。
///
/// ストーリーの内容方針（Google Playコンテンツレーティング対策）：
/// - 性的表現・暴力・薬物は一切含めない
/// - 借金、離婚、片思い、夜の街での息抜き、仕事の悩みなど
///   「ちょっと大人向け」な人間ドラマに留め、一般的な邦画・ドラマ程度の
///   表現強度を上限とする
class CitizenFlavorGenerator {
  static final Random _random = Random();

  static const _surnames = [
    '田中', '山本', '中村', '小林', '加藤', '吉田', '松本', '井上',
    '木村', '斎藤', '福岡', '博多', '川端', '祇園', '住吉',
  ];
  static const _givenNamesMale = ['翔太', '大輔', '健太', '拓也', '直樹', '亮', '悠斗'];
  static const _givenNamesFemale = ['美咲', '愛', '陽子', '沙也花', '結衣', '真由', '恵'];

  static const _jobsCommercial = ['雑貨店員', '飲食店スタッフ', 'カフェ店員', '屋台の店主', '会社員'];
  static const _jobsLandmark = ['神社の巫女', '駅員', '観光ガイド', '警備員'];
  static const _jobsNone = ['フリーランス', '大学生', '求職中', '自営業'];

  static const _storylinesGeneral = [
    '住宅ローンの返済に追われる毎日だが、週末に那珂川沿いを散歩するのがささやかな楽しみ。',
    '転職を考えているが、なかなか一歩を踏み出せずにいる。',
    '実家との折り合いが悪く、博多に出てきてから一人暮らしを続けている。',
    '副業を始めたばかりで、まだ本業の同僚には内緒にしている。',
    '離婚してから半年、休日は近所の公園でぼんやり過ごすことが増えた。',
  ];
  static const _storylinesNightlife = [
    '昼は真面目な会社員だが、夜は中洲のスナックに顔を出すのが唯一のストレス発散。',
    '同僚に片思い中。今日こそ声をかけようと決意しているが、まだ言えていない。',
    '夜遅くまで屋台で働き、朝方に帰宅する生活リズムが数年続いている。',
    '飲みの席でのちょっとした一言が原因で、友人と気まずい空気が続いている。',
  ];
  static const _storylinesAmbition = [
    '将来は自分の店を持つのが夢で、コツコツ貯金をしている。',
    '博多の観光をもっと盛り上げたいと、休日はSNSで地元の魅力を発信している。',
    '資格の勉強中で、通勤時間も参考書を手放さない。',
  ];

  static Map<String, String> generateProfile({
    required TileType? workTileType,
  }) {
    final isFemale = _random.nextBool();
    final given = isFemale
        ? _givenNamesFemale[_random.nextInt(_givenNamesFemale.length)]
        : _givenNamesMale[_random.nextInt(_givenNamesMale.length)];
    final surname = _surnames[_random.nextInt(_surnames.length)];
    final age = 20 + _random.nextInt(45); // 20-64歳

    String job;
    if (workTileType == TileType.commercial) {
      job = _jobsCommercial[_random.nextInt(_jobsCommercial.length)];
    } else if (workTileType == TileType.landmark) {
      job = _jobsLandmark[_random.nextInt(_jobsLandmark.length)];
    } else {
      job = _jobsNone[_random.nextInt(_jobsNone.length)];
    }

    final storyPool = [
      ..._storylinesGeneral,
      ..._storylinesNightlife,
      ..._storylinesAmbition,
    ];
    final storyline = storyPool[_random.nextInt(storyPool.length)];

    return {
      'name': '$surname $given',
      'age': age.toString(),
      'job': job,
      'storyline': storyline,
    };
  }
}
