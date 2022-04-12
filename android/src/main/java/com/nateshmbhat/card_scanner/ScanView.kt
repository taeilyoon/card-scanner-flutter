package com.nateshmbhat.card_scanner

import android.content.Context
import android.graphics.*
import android.graphics.drawable.Drawable
import android.os.Build
import android.text.TextPaint
import android.util.AttributeSet
import android.view.View
import androidx.annotation.RequiresApi

/**
 * TODO: document your custom view class.
 */
 class ScanView : View {


    private lateinit var textPaint: TextPaint
    private var textWidth: Float = 0f
    private var textHeight: Float = 0f


    constructor(context: Context) : super(context) {
        init(null, 0)
    }

    constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
        init(attrs, 0)
    }

    constructor(context: Context, attrs: AttributeSet, defStyle: Int) : super(
        context,
        attrs,
        defStyle
    ) {
        init(attrs, defStyle)
    }

    private fun init(attrs: AttributeSet?, defStyle: Int) {
        // Load attributes
        val a = context.obtainStyledAttributes(
            attrs, R.styleable.ScanView, defStyle, 0
        )

        a.recycle()
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        // TODO: consider storing these as member variables to reduce
        // allocations per draw cycle.
        val paddingLeft = 60
        val paddingTop = height/3
        val paddingRight =60
        val paddingBottom =400

        val contentWidth = width - paddingLeft - paddingRight
        val contentHeight = (contentWidth/330)*200 * 1.4
        val holeBorderRadius = 16.0f;

        val rect = RectF(8.0f,8.0f,8.0f,8.0f );
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), Paint().apply { color = Color.parseColor(
            "#88000000"
        )});
        val path = Path()
        path.rewind()
        path.addRoundRect(
            RectF(
                paddingLeft.toFloat(),
                (height/2 - contentHeight/2).toFloat(),
                (paddingLeft + contentWidth).toFloat(),
                (height/2 + contentHeight/2).toFloat()
            ),
            holeBorderRadius,
            holeBorderRadius,
            Path.Direction.CW
        )

        canvas.drawPath(path, Paint().apply {
            isAntiAlias = true
            strokeWidth = 4f
            color = Color.parseColor("#F45185")
            style = Paint.Style.STROKE
        })
        canvas.save();

        canvas.drawRoundRect(
            RectF(
                paddingLeft.toFloat(),
                (height/2 - contentHeight/2).toFloat(),
                (paddingLeft + contentWidth).toFloat(),
                (height/2 + contentHeight/2).toFloat()
            ), holeBorderRadius, holeBorderRadius,  Paint().apply {
                isAntiAlias = true
                xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
            }
        )
        canvas.save();
    }
}