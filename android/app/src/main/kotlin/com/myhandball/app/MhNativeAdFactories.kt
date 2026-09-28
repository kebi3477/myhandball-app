package com.myhandball.app

import android.content.Context
import android.graphics.Color
import android.graphics.Outline
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * 네이티브 광고 카드 3종 (디자인 핸드오프 "네이티브 광고").
 *
 * 치수는 Dart `NativeAdSlot`의 높이 계산과 맞물려 있다 — 여기 고정값을
 * 바꾸면 `lib/ui/ads/widgets/native_ad_slot.dart`도 같이 고친다.
 * 글자 크기는 dp로 둔다. 시스템 글꼴 크기를 따라 커지면 Flutter가 잡아 둔
 * 높이를 넘친다.
 */
object MhNativeAdFactories {
    fun register(engine: FlutterEngine, context: Context) {
        GoogleMobileAdsPlugin.registerNativeAdFactory(engine, "mh_feed_media", FeedMedia(context))
        GoogleMobileAdsPlugin.registerNativeAdFactory(engine, "mh_list_small", ListSmall(context))
        GoogleMobileAdsPlugin.registerNativeAdFactory(engine, "mh_cheer_post", CheerPost(context))
    }

    fun unregister(engine: FlutterEngine) {
        for (id in listOf("mh_feed_media", "mh_list_small", "mh_cheer_post")) {
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(engine, id)
        }
    }

    /** A. 홈 — 미디어형. */
    private class FeedMedia(private val context: Context) : NativeAdFactory {
        override fun createNativeAd(ad: NativeAd, options: MutableMap<String, Any>?): NativeAdView {
            val ui = Ui(context, options)
            val view = NativeAdView(context)
            val card = ui.card(radius = 20f, top = 14, horizontal = 16, bottom = 16)

            val icon = ui.icon(40, radius = 10f)
            val headline = ui.text(14f, Weight.Bold, ui.palette.text)
            val body = ui.text(12f, Weight.Regular, ui.palette.textSub)
            val adChoices = ui.adChoices()
            card.addView(
                ui.row(gap = 10, children = listOf(
                    icon,
                    ui.column(listOf(ui.row(gap = 6, children = listOf(ui.badge(), headline), weightLast = true), body))
                        .weighted(),
                    adChoices,
                )),
            )

            val media = ui.media(ratio = 16f / 9f, radius = 14f)
            card.addView(media.frame, ui.gapTop(12))

            val advertiser = ui.text(12f, Weight.Regular, ui.palette.textFaint)
            val cta = ui.cta(height = 36, horizontal = 16, size = 13f, radius = 18f)
            card.addView(
                ui.row(gap = 10, children = listOf(advertiser.weighted(), cta)),
                ui.gapTop(12),
            )

            view.addView(card)
            view.headlineView = headline
            view.bodyView = body
            view.iconView = icon
            view.advertiserView = advertiser
            view.callToActionView = cta
            view.mediaView = media.view
            view.adChoicesView = adChoices.getChildAt(0) as AdChoicesView
            bind(view, ad, headline, body, icon, advertiser, cta, "자세히 보기")
            return view
        }
    }

    /** B. 일정 목록 — 소형. */
    private class ListSmall(private val context: Context) : NativeAdFactory {
        override fun createNativeAd(ad: NativeAd, options: MutableMap<String, Any>?): NativeAdView {
            val ui = Ui(context, options)
            val view = NativeAdView(context)
            val card = ui.card(radius = 20f, top = 14, horizontal = 16, bottom = 14)

            val icon = ui.icon(44, radius = 10f)
            val headline = ui.text(14f, Weight.Bold, ui.palette.text)
            val body = ui.text(12f, Weight.Regular, ui.palette.textSub)
            val cta = ui.cta(height = 34, horizontal = 14, size = 12f, radius = 17f)
            card.addView(
                ui.row(gap = 12, children = listOf(
                    icon,
                    ui.column(listOf(ui.row(gap = 6, children = listOf(ui.badge(), headline), weightLast = true), body))
                        .weighted(),
                    cta,
                )),
            )

            view.addView(card)
            view.headlineView = headline
            view.bodyView = body
            view.iconView = icon
            view.callToActionView = cta
            bind(view, ad, headline, body, icon, null, cta, "열기")
            return view
        }
    }

    /** C. 응원 게시판 — 게시글형. 일반 응원글과 같은 모양, 좋아요·메뉴 없음. */
    private class CheerPost(private val context: Context) : NativeAdFactory {
        override fun createNativeAd(ad: NativeAd, options: MutableMap<String, Any>?): NativeAdView {
            val ui = Ui(context, options)
            val view = NativeAdView(context)
            val card = ui.card(radius = 16f, top = 14, horizontal = 16, bottom = 14)

            // 시안은 작성자 자리에 광고주명을 쓰지만 AdMob은 제목(headline)을
            // 반드시 보여야 해서 그 자리에 제목을 둔다.
            val icon = ui.icon(28, radius = 8f)
            val headline = ui.text(13f, Weight.Bold, ui.palette.text)
            val adChoices = ui.adChoices()
            card.addView(
                ui.row(gap = 8, children = listOf(icon, headline.weighted(), ui.badge(), adChoices)),
            )

            // 본문은 2줄까지. 높이를 고정해야 Flutter 쪽 계산과 맞는다.
            val body = ui.text(14f, Weight.Regular, ui.palette.text, maxLines = 2)
            ui.lineHeight(body, 14f * 1.55f)
            card.addView(body, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ui.dp(44)).apply {
                topMargin = ui.dp(10)
            })

            val media = ui.media(ratio = 2f, radius = 12f)
            card.addView(media.frame, ui.gapTop(10))

            val cta = ui.cta(height = 40, horizontal = 0, size = 13f, radius = 12f)
            card.addView(cta, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ui.dp(40)).apply {
                topMargin = ui.dp(10)
            })

            view.addView(card)
            view.headlineView = headline
            view.bodyView = body
            view.iconView = icon
            view.callToActionView = cta
            view.mediaView = media.view
            view.adChoicesView = adChoices.getChildAt(0) as AdChoicesView
            headline.text = ad.headline
            body.text = ad.body ?: ""
            bindCommon(view, ad, icon, cta, "주문하러 가기")
            return view
        }
    }

    private fun bind(
        view: NativeAdView,
        ad: NativeAd,
        headline: TextView,
        body: TextView,
        icon: ImageView,
        advertiser: TextView?,
        cta: TextView,
        defaultCta: String,
    ) {
        headline.text = ad.headline
        body.text = ad.body ?: ""
        body.visibility = if (ad.body == null) View.GONE else View.VISIBLE
        advertiser?.text = ad.advertiser ?: ""
        bindCommon(view, ad, icon, cta, defaultCta)
    }

    private fun bindCommon(view: NativeAdView, ad: NativeAd, icon: ImageView, cta: TextView, defaultCta: String) {
        val drawable = ad.icon?.drawable
        if (drawable == null) {
            icon.visibility = View.INVISIBLE
        } else {
            icon.setImageDrawable(drawable)
        }
        cta.text = ad.callToAction ?: defaultCta
        view.setNativeAd(ad)
    }

    private enum class Weight { Regular, Bold, ExtraBold }

    private data class Palette(
        val card: Int,
        val border: Int,
        val text: Int,
        val textSub: Int,
        val textFaint: Int,
    )

    private class Media(val frame: FrameLayout, val view: MediaView)

    /** 뷰 조립 도우미. 색은 핸드오프 토큰 그대로다. */
    private class Ui(val context: Context, options: Map<String, Any>?) {
        val palette = if (options?.get("dark") == true) {
            Palette(0xFF222222.toInt(), 0xFF333333.toInt(), Color.WHITE, 0xFF6D6D6D.toInt(), 0xFF5D5D5D.toInt())
        } else {
            Palette(0xFFF2F2F2.toInt(), 0xFFE5E5E5.toInt(), 0xFF111111.toInt(), 0xFF6B6B6B.toInt(), 0xFF858585.toInt())
        }

        fun dp(v: Int): Int = dpf(v.toFloat()).toInt()
        fun dpf(v: Float): Float =
            TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, context.resources.displayMetrics)

        fun rounded(color: Int, radius: Float, strokeColor: Int? = null) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dpf(radius)
            if (strokeColor != null) setStroke(dp(1), strokeColor)
        }

        fun card(radius: Float, top: Int, horizontal: Int, bottom: Int) = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(palette.card, radius)
            setPadding(dp(horizontal), dp(top), dp(horizontal), dp(bottom))
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }

        fun row(gap: Int, children: List<View>, weightLast: Boolean = false) = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            children.forEachIndexed { i, child ->
                val lp = (child.layoutParams as? LinearLayout.LayoutParams)
                    ?: LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT,
                    )
                if (weightLast && i == children.lastIndex) {
                    lp.width = 0
                    lp.weight = 1f
                }
                if (i > 0) lp.marginStart = dp(gap)
                addView(child, lp)
            }
        }

        fun column(children: List<View>) = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            children.forEachIndexed { i, child ->
                addView(child, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
                ).apply { if (i > 0) topMargin = dp(2) })
            }
        }

        fun text(size: Float, weight: Weight, color: Int, maxLines: Int = 1) = TextView(context).apply {
            setTextSize(TypedValue.COMPLEX_UNIT_DIP, size)
            setTextColor(color)
            typeface = font(weight)
            includeFontPadding = false
            this.maxLines = maxLines
            ellipsize = TextUtils.TruncateAt.END
        }

        fun lineHeight(view: TextView, height: Float) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) view.lineHeight = dpf(height).toInt()
        }

        fun icon(size: Int, radius: Float) = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            clip(this, radius)
            layoutParams = LinearLayout.LayoutParams(dp(size), dp(size))
        }

        fun badge() = text(10f, Weight.ExtraBold, 0xFF111111.toInt()).apply {
            text = "광고"
            background = rounded(0xFFFFC800.toInt(), 4f)
            setPadding(dp(6), dp(2), dp(6), dp(2))
        }

        fun cta(height: Int, horizontal: Int, size: Float, radius: Float) =
            text(size, Weight.Bold, Color.WHITE).apply {
                gravity = Gravity.CENTER
                background = rounded(0xFF0068FF.toInt(), radius)
                setPadding(dp(horizontal), 0, dp(horizontal), 0)
                layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, dp(height))
            }

        /** AdChoices 자리 — 18×18, 테두리. 아이콘은 SDK가 채운다. 가리지 않는다. */
        fun adChoices() = FrameLayout(context).apply {
            background = rounded(Color.TRANSPARENT, 4f, palette.border)
            addView(AdChoicesView(context), FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT,
            ))
            layoutParams = LinearLayout.LayoutParams(dp(18), dp(18))
        }

        fun media(ratio: Float, radius: Float): Media {
            val media = MediaView(context).apply { setImageScaleType(ImageView.ScaleType.CENTER_CROP) }
            val frame = AspectFrame(context, ratio).apply {
                setBackgroundColor(palette.border)
                clip(this, radius)
                addView(media, FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT,
                ))
            }
            return Media(frame, media)
        }

        fun gapTop(gap: Int) = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(gap) }

        private fun clip(view: View, radius: Float) {
            val r = dpf(radius)
            view.outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(v: View, outline: Outline) {
                    outline.setRoundRect(0, 0, v.width, v.height, r)
                }
            }
            view.clipToOutline = true
        }

        /** 앱에 번들된 Pretendard를 그대로 쓴다. 못 읽으면 시스템 글꼴. */
        private fun font(weight: Weight): Typeface {
            val file = when (weight) {
                Weight.Regular -> "Pretendard-Regular.otf"
                Weight.Bold -> "Pretendard-Bold.otf"
                Weight.ExtraBold -> "Pretendard-ExtraBold.otf"
            }
            return fonts.getOrPut(file) {
                runCatching {
                    val key = FlutterInjector.instance().flutterLoader()
                        .getLookupKeyForAsset("assets/fonts/$file")
                    Typeface.createFromAsset(context.assets, key)
                }.getOrElse { if (weight == Weight.Regular) Typeface.DEFAULT else Typeface.DEFAULT_BOLD }
            }
        }

        companion object {
            private val fonts = mutableMapOf<String, Typeface>()
        }
    }

    /** 폭에 맞춰 높이를 비율로 정하는 틀 (MediaView 16:9 · 2:1). */
    private class AspectFrame(context: Context, private val ratio: Float) : FrameLayout(context) {
        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            val width = MeasureSpec.getSize(widthMeasureSpec)
            val height = (width / ratio).toInt()
            super.onMeasure(
                MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY),
            )
        }
    }

    private fun View.weighted(): View = apply {
        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
    }
}
