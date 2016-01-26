//! Copyright (C) 2016 Sven Meyer <meyer@modell-aachen.de>
//!
//! This program is free software: you can redistribute it and/or modify it
//! under the terms of the GNU General Public License as published by the Free
//! Software Foundation, either version 3 of the License, or (at your option)
//! any later version.
//!
//! This program is distributed in the hope that it will be useful, but WITHOUT
//! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//! FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//! more details.
//!
//! You should have received a copy of the GNU General Public License along
//! with this program.  If not, see <http://www.gnu.org/licenses/>.


using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class BinaryEleganceView extends Ui.WatchFace {
  const ICON_ALARM = "0";
  const ICON_POWER = "1";
  const ICON_NOTIFICATION = "2";
  const ICON_BLUETOOTH = "3";
  const ICON_OFFSET = 30;
  const JUSTIFICATION = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
  const SQUARE_SIZE = 14;

  hidden var active = false;
  hidden var centerX, centerY, screenH, screenW;
  hidden var ctx;
  hidden var colors = {};
  hidden var iconFont;
  hidden var is24Hour = false;
  hidden var shapeOffset;

  function onLayout(dc) {
    ctx = dc;
    screenH = dc.getHeight();
    screenW = dc.getWidth();
    centerX = screenW/2;
    centerY = screenH/2;

    var settings = Sys.getDeviceSettings();
    is24Hour = settings.is24Hour;

    var shape = settings.screenShape;
    if (shape == Sys.SCREEN_SHAPE_RECTANGLE) {
      centerY -= 5;
      shapeOffset = 15;
    } else {
      shapeOffset = shape == Sys.SCREEN_SHAPE_ROUND ? 30 : 20;
    }
  }

  function onShow() {
    iconFont = Ui.loadResource(Rez.Fonts.id_font);

    var app = App.getApp();
    colors.put("bg", app.getProperty("bg"));
    colors.put("hbg", app.getProperty("hbg"));
    colors.put("hfg", app.getProperty("hfg"));
    colors.put("mbg", app.getProperty("mbg"));
    colors.put("mfg", app.getProperty("mfg"));
    colors.put(ICON_ALARM, app.getProperty("ac"));
    colors.put(ICON_POWER, app.getProperty("pc"));
    colors.put(ICON_NOTIFICATION, app.getProperty("nc"));
    colors.put(ICON_BLUETOOTH, app.getProperty("bc"));
  }

  function onHide() {
    colors = null;
    iconFont = null;
  }

  function onUpdate(dc) {
    setForeground(Gfx.COLOR_TRANSPARENT);
    dc.clear();

    var clockTime = Sys.getClockTime();
    drawHours(clockTime.hour);
    drawMinutes(clockTime.min);

    var stats = Sys.getSystemStats();
    drawOther(active? clockTime.sec : stats.battery);

    drawIcons();
  }

  function onExitSleep() {
    active = true;
  }

  function onEnterSleep() {
    active = false;
    Ui.requestUpdate();
  }

  hidden function drawHours(hours) {
    var x, y, digit;
    var bounds = 2;
    if (!is24Hour) {
        bounds = 1;
        if (hours > 12) {
          hours -= 12;
        }
    }

    x = centerX - 5.5*SQUARE_SIZE;
    y = centerY + 4.5*SQUARE_SIZE;
    digit = hours/10;

    for (var i = bounds; i > 0; --i) {
      setForeground(colors.get(digit & i > 0 ? "hfg" : "hbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }

    x = centerX - 3.5*SQUARE_SIZE;
    y = centerY + 2.5*SQUARE_SIZE;
    digit = hours%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "hfg" : "hbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }
  }

  hidden function drawMinutes(minutes) {
    var x, y, digit;

    x = centerX - 1.5*SQUARE_SIZE;
    y = centerY + 2.5*SQUARE_SIZE;
    digit = minutes/10;

    for (var i = 0; i < 3; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }

    x = centerX + 0.5*SQUARE_SIZE;
    y = centerY + 2.5*SQUARE_SIZE;
    digit = minutes%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }
  }

  hidden function drawOther(other) {
    var value = (other > 99 ? 99 : other).toNumber();
    var x, y, digit;

    x = centerX + 2.5*SQUARE_SIZE;
    y = centerY + 2.5*SQUARE_SIZE;
    digit = value/10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }

    x = centerX + 4.5*SQUARE_SIZE;
    y = centerY + 2.5*SQUARE_SIZE;
    digit = value%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*SQUARE_SIZE);
    }
  }

  hidden function drawIcons() {
    var icons = {};
    var settings = Sys.getDeviceSettings();

    if (settings.alarmCount > 0) {
      icons.put("1", ICON_ALARM);
    }

    if (settings.phoneConnected) {
      icons.put("2", ICON_BLUETOOTH);
    }

    if (settings.notificationCount > 0) {
      icons.put("3", ICON_NOTIFICATION);
    }

    var size = icons.size();
    if (size > 0) {
      var values = icons.values();
      var shape = settings.screenShape;
      var x = centerX - (size == 1 ? 0 : (size == 2 ? ICON_OFFSET/2 : ICON_OFFSET));
      var y = screenH - shapeOffset;
      for (var i = 0; i < size; ++i) {
        ctx.setColor(colors.get(values[i]), colors.get("bg"));
        ctx.drawText(x, y, iconFont, values[i], JUSTIFICATION);
        x += ICON_OFFSET;
      }
    }
  }

  hidden function drawSquare(x, y) {
    ctx.fillRectangle(x, y, SQUARE_SIZE, SQUARE_SIZE);
  }

  hidden function setForeground(color) {
    ctx.setColor(color, colors.get("bg"));
  }
}
