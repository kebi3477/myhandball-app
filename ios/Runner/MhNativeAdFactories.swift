import CoreText
import Flutter
import GoogleMobileAds
import UIKit
import google_mobile_ads

/// 네이티브 광고 카드 3종 (디자인 핸드오프 "네이티브 광고").
///
/// 치수는 Dart `NativeAdSlot`의 높이 계산과 맞물려 있다 — 여기 고정값을
/// 바꾸면 `lib/ui/ads/widgets/native_ad_slot.dart`도 같이 고친다.
/// 글자 크기는 Dynamic Type을 따르지 않는다. 커지면 Flutter가 잡아 둔
/// 높이를 넘친다. Android 쪽은 `MhNativeAdFactories.kt`.
enum MhNativeAdFactories {
  static func register(_ registry: FlutterPluginRegistry) {
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registry, factoryId: "mh_feed_media", nativeAdFactory: FeedMedia())
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registry, factoryId: "mh_list_small", nativeAdFactory: ListSmall())
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      registry, factoryId: "mh_cheer_post", nativeAdFactory: CheerPost())
  }
}

/// A. 홈 — 미디어형.
private final class FeedMedia: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ ad: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
    let ui = AdUi(customOptions)
    let view = ui.card(radius: 20)

    let icon = ui.icon(40, radius: 10)
    let headline = ui.label(14, .bold, ui.palette.text)
    let body = ui.label(12, .regular, ui.palette.textSub)
    let texts = ui.vstack([ui.hstack([ui.badge(), headline], spacing: 6), body], spacing: 2)
    let adChoices = ui.adChoices()
    let top = ui.hstack([icon, texts, adChoices], spacing: 10)

    let media = ui.media(ratio: 16.0 / 9.0, radius: 14)

    let advertiser = ui.label(12, .regular, ui.palette.textFaint)
    let cta = ui.cta(height: 36, horizontal: 16, size: 13, radius: 18)
    let bottom = ui.hstack([advertiser, cta], spacing: 10)

    ui.pin(ui.vstack([top, media, bottom], spacing: 12), in: view, top: 14, horizontal: 16)

    view.headlineView = headline
    view.bodyView = body
    view.iconView = icon
    view.advertiserView = advertiser
    view.callToActionView = cta
    view.mediaView = media
    view.adChoicesView = adChoices

    headline.text = ad.headline
    body.text = ad.body
    body.isHidden = ad.body == nil
    advertiser.text = ad.advertiser
    media.mediaContent = ad.mediaContent
    AdUi.bind(view, ad, icon: icon, cta: cta, defaultCta: "자세히 보기")
    return view
  }
}

/// B. 일정 목록 — 소형.
private final class ListSmall: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ ad: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
    let ui = AdUi(customOptions)
    let view = ui.card(radius: 20)

    let icon = ui.icon(44, radius: 10)
    let headline = ui.label(14, .bold, ui.palette.text)
    let body = ui.label(12, .regular, ui.palette.textSub)
    let texts = ui.vstack([ui.hstack([ui.badge(), headline], spacing: 6), body], spacing: 2)
    let cta = ui.cta(height: 34, horizontal: 14, size: 12, radius: 17)

    ui.pin(ui.hstack([icon, texts, cta], spacing: 12), in: view, top: 14, horizontal: 16)

    view.headlineView = headline
    view.bodyView = body
    view.iconView = icon
    view.callToActionView = cta

    headline.text = ad.headline
    body.text = ad.body
    body.isHidden = ad.body == nil
    AdUi.bind(view, ad, icon: icon, cta: cta, defaultCta: "열기")
    return view
  }
}

/// C. 응원 게시판 — 게시글형. 일반 응원글과 같은 모양, 좋아요·메뉴 없음.
private final class CheerPost: NSObject, FLTNativeAdFactory {
  func createNativeAd(_ ad: NativeAd, customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {
    let ui = AdUi(customOptions)
    let view = ui.card(radius: 16)

    // 시안은 작성자 자리에 광고주명을 쓰지만 AdMob은 제목(headline)을
    // 반드시 보여야 해서 그 자리에 제목을 둔다.
    let icon = ui.icon(28, radius: 8)
    let headline = ui.label(13, .bold, ui.palette.text)
    let adChoices = ui.adChoices()
    let top = ui.hstack([icon, headline, ui.badge(), adChoices], spacing: 8)

    // 본문은 2줄까지. 높이를 고정해야 Flutter 쪽 계산과 맞는다.
    let body = ui.label(14, .regular, ui.palette.text, lines: 2)
    body.heightAnchor.constraint(equalToConstant: 44).isActive = true

    let media = ui.media(ratio: 2, radius: 12)
    let cta = ui.cta(height: 40, horizontal: 0, size: 13, radius: 12)

    ui.pin(ui.vstack([top, body, media, cta], spacing: 10), in: view, top: 14, horizontal: 16)

    view.headlineView = headline
    view.bodyView = body
    view.iconView = icon
    view.callToActionView = cta
    view.mediaView = media
    view.adChoicesView = adChoices

    headline.text = ad.headline
    body.attributedText = AdUi.lineHeight(ad.body ?? "", font: body.font, height: 14 * 1.55)
    body.lineBreakMode = .byTruncatingTail
    media.mediaContent = ad.mediaContent
    AdUi.bind(view, ad, icon: icon, cta: cta, defaultCta: "주문하러 가기")
    return view
  }
}

/// 뷰 조립 도우미. 색은 핸드오프 토큰 그대로다.
private struct AdUi {
  struct Palette {
    let card, border, text, textSub, textFaint: UIColor
  }

  enum Weight { case regular, bold, extraBold }

  let palette: Palette

  init(_ options: [AnyHashable: Any]?) {
    let dark = (options?["dark"] as? Bool) ?? false
    palette = dark
      ? Palette(card: .hex(0x222222), border: .hex(0x333333), text: .white,
                textSub: .hex(0x6D6D6D), textFaint: .hex(0x5D5D5D))
      : Palette(card: .hex(0xF2F2F2), border: .hex(0xE5E5E5), text: .hex(0x111111),
                textSub: .hex(0x6B6B6B), textFaint: .hex(0x858585))
  }

  func card(radius: CGFloat) -> NativeAdView {
    let view = NativeAdView()
    view.backgroundColor = palette.card
    view.layer.cornerRadius = radius
    view.clipsToBounds = true
    return view
  }

  /// 위·좌우만 붙인다. 높이는 Flutter가 정한 값이라 아래까지 붙이면
  /// 소수점 반올림 차이로 제약이 충돌한다.
  func pin(_ content: UIView, in view: UIView, top: CGFloat, horizontal: CGFloat) {
    content.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: view.topAnchor, constant: top),
      content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontal),
      content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontal),
      content.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
    ])
  }

  func hstack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = spacing
    return stack
  }

  func vstack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = spacing
    return stack
  }

  func label(_ size: CGFloat, _ weight: Weight, _ color: UIColor, lines: Int = 1) -> UILabel {
    let label = UILabel()
    label.font = AdUi.font(size, weight)
    label.textColor = color
    label.numberOfLines = lines
    label.lineBreakMode = .byTruncatingTail
    label.setContentHuggingPriority(.defaultLow, for: .horizontal)
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return label
  }

  func icon(_ size: CGFloat, radius: CGFloat) -> UIImageView {
    let view = UIImageView()
    view.contentMode = .scaleAspectFill
    view.layer.cornerRadius = radius
    view.clipsToBounds = true
    fixed(view, width: size, height: size)
    return view
  }

  func badge() -> UILabel {
    let label = PaddedLabel(insets: UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
    label.text = "광고"
    label.font = AdUi.font(10, .extraBold)
    label.textColor = .hex(0x111111)
    label.backgroundColor = .hex(0xFFC800)
    label.layer.cornerRadius = 4
    label.clipsToBounds = true
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentCompressionResistancePriority(.required, for: .horizontal)
    return label
  }

  /// CTA는 SDK가 탭을 받으므로 사용자 상호작용을 끈 라벨로 둔다.
  func cta(height: CGFloat, horizontal: CGFloat, size: CGFloat, radius: CGFloat) -> UILabel {
    let label = PaddedLabel(insets: UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal))
    label.font = AdUi.font(size, .bold)
    label.textColor = .white
    label.textAlignment = .center
    label.backgroundColor = .hex(0x0068FF)
    label.layer.cornerRadius = radius
    label.clipsToBounds = true
    label.isUserInteractionEnabled = false
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentCompressionResistancePriority(.required, for: .horizontal)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.heightAnchor.constraint(equalToConstant: height).isActive = true
    return label
  }

  /// AdChoices 자리 — 18×18, 테두리. 아이콘은 SDK가 채운다. 가리지 않는다.
  func adChoices() -> AdChoicesView {
    let view = AdChoicesView()
    view.layer.cornerRadius = 4
    view.layer.borderWidth = 1
    view.layer.borderColor = palette.border.cgColor
    fixed(view, width: 18, height: 18)
    return view
  }

  func media(ratio: CGFloat, radius: CGFloat) -> MediaView {
    let view = MediaView()
    view.backgroundColor = palette.border
    view.contentMode = .scaleAspectFill
    view.layer.cornerRadius = radius
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / ratio).isActive = true
    return view
  }

  private func fixed(_ view: UIView, width: CGFloat, height: CGFloat) {
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.widthAnchor.constraint(equalToConstant: width),
      view.heightAnchor.constraint(equalToConstant: height),
    ])
  }

  static func bind(_ view: NativeAdView, _ ad: NativeAd, icon: UIImageView, cta: UILabel, defaultCta: String) {
    icon.image = ad.icon?.image
    icon.alpha = ad.icon == nil ? 0 : 1
    cta.text = ad.callToAction ?? defaultCta
    view.nativeAd = ad
  }

  static func lineHeight(_ text: String, font: UIFont, height: CGFloat) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.minimumLineHeight = height
    style.maximumLineHeight = height
    style.lineBreakMode = .byTruncatingTail
    return NSAttributedString(string: text, attributes: [.font: font, .paragraphStyle: style])
  }

  // MARK: 글꼴 — 앱에 번들된 Pretendard를 그대로 쓴다. 못 읽으면 시스템 글꼴.

  private static let registerFonts: Void = {
    for file in ["Pretendard-Regular.otf", "Pretendard-Bold.otf", "Pretendard-ExtraBold.otf"] {
      let key = FlutterDartProject.lookupKey(forAsset: "assets/fonts/\(file)")
      guard let path = Bundle.main.path(forResource: key, ofType: nil) else { continue }
      CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: path) as CFURL, .process, nil)
    }
  }()

  static func font(_ size: CGFloat, _ weight: Weight) -> UIFont {
    _ = registerFonts
    let (name, system): (String, UIFont.Weight) = switch weight {
    case .regular: ("Pretendard-Regular", .regular)
    case .bold: ("Pretendard-Bold", .bold)
    case .extraBold: ("Pretendard-ExtraBold", .heavy)
    }
    return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: system)
  }
}

private final class PaddedLabel: UILabel {
  private let insets: UIEdgeInsets

  init(insets: UIEdgeInsets) {
    self.insets = insets
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: insets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + insets.left + insets.right,
                  height: size.height + insets.top + insets.bottom)
  }
}

private extension UIColor {
  static func hex(_ rgb: UInt32) -> UIColor {
    UIColor(red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1)
  }
}
