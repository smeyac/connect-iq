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

  hidden var active = false;
  hidden var batteryOffset;
  hidden var centerX, centerY, screenH, screenW;
  hidden var ctx;
  hidden var colors = {};
  hidden var iconFont;
  hidden var is24Hour = false;
  hidden var shapeOffset;
  hidden var squareSize;

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
    colors.put("bg", app.getProperty("background"));
    colors.put("hbg", app.getProperty("hoursInactive"));
    colors.put("hfg", app.getProperty("hoursActive"));
    colors.put("mbg", app.getProperty("minutesInactive"));
    colors.put("mfg", app.getProperty("minutesActive"));
    colors.put("obg", app.getProperty("otherInactive"));
    colors.put("ofg", app.getProperty("otherActive"));
    colors.put(ICON_ALARM, app.getProperty("alarmColor"));
    colors.put(ICON_POWER, app.getProperty("powerColor"));
    colors.put(ICON_NOTIFICATION, app.getProperty("notificationsColor"));
    colors.put(ICON_BLUETOOTH, app.getProperty("bluetoothColor"));

    squareSize = app.getProperty("squareSize");
    batteryOffset = app.getProperty("showOther") ? 0 : 2;
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

    if (batteryOffset == 0) {
      var stats = Sys.getSystemStats();
      drawOther(active? clockTime.sec : stats.battery);
    }

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

    x = centerX - (5.5-batteryOffset)*squareSize;
    y = centerY + 4.5*squareSize;
    digit = hours/10;

    for (var i = bounds; i > 0; --i) {
      setForeground(colors.get(digit & i > 0 ? "hfg" : "hbg"));
      drawSquare(x, y - 2*i*squareSize);
    }

    x = centerX - (3.5-batteryOffset)*squareSize;
    y = centerY + 2.5*squareSize;
    digit = hours%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "hfg" : "hbg"));
      drawSquare(x, y - 2*i*squareSize);
    }
  }

  hidden function drawMinutes(minutes) {
    var x, y, digit;

    x = centerX - (1.5-batteryOffset)*squareSize;
    y = centerY + 2.5*squareSize;
    digit = minutes/10;

    for (var i = 0; i < 3; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*squareSize);
    }

    x = centerX + (0.5+batteryOffset)*squareSize;
    y = centerY + 2.5*squareSize;
    digit = minutes%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "mfg" : "mbg"));
      drawSquare(x, y - 2*i*squareSize);
    }
  }

  hidden function drawOther(other) {
    var value = (other > 99 ? 99 : other).toNumber();
    var x, y, digit;

    x = centerX + 2.5*squareSize;
    y = centerY + 2.5*squareSize;
    digit = value/10;

    var bounds = active ? 3 : 4;
    for (var i = 0; i < bounds; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "ofg" : "obg"));
      drawSquare(x, y - 2*i*squareSize);
    }

    x = centerX + 4.5*squareSize;
    y = centerY + 2.5*squareSize;
    digit = value%10;

    for (var i = 0; i < 4; ++i) {
      setForeground(colors.get(digit & (1 << i) > 0 ? "ofg" : "obg"));
      drawSquare(x, y - 2*i*squareSize);
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
    ctx.fillRectangle(x, y, squareSize, squareSize);
  }

  hidden function setForeground(color) {
    ctx.setColor(color, colors.get("bg"));
  }
}
