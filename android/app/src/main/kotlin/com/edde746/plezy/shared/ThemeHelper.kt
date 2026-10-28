package com.edde746.plezy.shared

import android.graphics.Color

object ThemeHelper {
  fun themeColor(mode: String?): Int? = when (mode) {
    "oled" -> Color.BLACK
    "dark" -> Color.parseColor("#0E0F12")
    "nocturne" -> Color.parseColor("#0B0D12")
    "light" -> Color.parseColor("#F7F7F8")
    else -> null
  }
}
