# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    $appcode = "elten"

    # An identifier used for two-factor authentication and APNS
    if Store["appid"] == nil
      # We will generate random, user-readable, identifier
      $appid = "iOS_"
      chars = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a
      60.times do
        $appid << chars[rand(chars.length - 1)]
      end
      Store["appid"] = $appid
    end

    # Permission for sending Push Notifications
    if Store["notificationsasked"] == nil
      Store["notificationsasked"] = true
      UI.alert({:title => "Do you want to enable notifications?", :message => "If you wish, you can configure Elten to receive push notifications regarding new messages, posts in followed threads and so on.", :default => "Yes", :cancel => "No"}) { |ans|
        if ans == :default
          registernotifications
          Store["registernotifications"] = true
        end
      }
    elsif Store["registernotifications"] == true
      registernotifications
    end

    # Audio Session Initialization
    err = Pointer.new(:object)
    AVAudioSession.sharedInstance.setCategory(AVAudioSessionCategoryAmbient, error: err)
    AVAudioSession.sharedInstance.setActive(true, error: err)

    # Create Navigation Instance and Proceed to the Welcome Screen
    welcome_screen = WelcomeScreen.new
    navigation = UI::Navigation.new(welcome_screen)
$appdelegate=self
    $app = UI::Application.new(navigation, self)
    $app.start
  end

  def applicationWillResignActive(app)
    $streamer.pause if $streamer != nil
  end

  def registernotifications
    types = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound
    settings = UIUserNotificationSettings.settingsForTypes(types, categories: nil)
    UIApplication.sharedApplication.registerUserNotificationSettings(settings)

    UIApplication.sharedApplication.registerForRemoteNotifications
  end

  def application(application, didRegisterForRemoteNotificationsWithDeviceToken: device_token)
    # The Device Token we will send base64-encoded cause it is saved in binary format

    erequest("apns", {"ac" => "register", "appid" => Store["appid"], "devicetoken" => device_token.MSBase64Encoding}) { |rpl|
      if rpl["code"] == 200
        $apns_token = device_token
      else
        UI.alert({:title => "Failed to register for Push Notifications", :message => rpl["errmsg"]}) { }
      end
    }
  end

  def application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    Net.get(create_query("apns", {"ac" => "unregister", "appid" => Store["appid"]})) { }
  end

  def applicationDidBecomeActive(application)
    # On application show up, reset any badges
    UIApplication.sharedApplication.applicationIconBadgeNumber = 0
  end

  def application(application, didReceiveRemoteNotification: userInfo)
    snd = userInfo["aps"]["sound"]
    play($1) if snd != nil and ((/audio\/([^.]+)\.m4a/) =~ snd) != nil
  end
end
