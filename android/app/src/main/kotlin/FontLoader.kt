package com.example.flutter_application_1

import android.content.Context
import android.graphics.Typeface
import android.widget.TextView

object FontLoader {
    fun applyFont(context: Context, view: TextView, fontName: String) {
        try {
            val typeface = Typeface.createFromAsset(context.assets, "font/$fontName")
            view.typeface = typeface
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}