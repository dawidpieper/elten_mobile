# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class MainScreen < UI::Screen
  def on_show
    play("signal")
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = "Elten"

    # Stop local background tasks
    if $tmptask != nil
      $tmptask.stop
      $tmptask = nil
    end

    erequest("handshake") do |resp|
            if resp["code"] == 200
        self.navigation.title = resp["handshake"]
      end
    end
  end

  def on_load
    $screen = self

    background = UI::View.new
    background.flex = 1
    background.margin = 25
    background.background_color = :white
    self.view.add_child(background)

    list = UI::List.new
    list.data_source = ["Messages", "Forum", "Log out", "Show debug info"]
    list.margin = 5
    list.height = 250
    background.add_child(list)

    list.on(:select) do |str, ind|
      # 'str' is a string with option name, 'ind' is option index
      case ind
      when 0 #messages
        messages_screen = MessagesScreen.new
        self.navigation.push(messages_screen)
      when 1 #forum
        forum_screen = ForumScreen.new
        self.navigation.push(forum_screen)
      when 2 #logout
        UI.alert({:title => "Confirm", :message => "Are you sure you want to log out of Elten?", :default => "Yes", :cancel => "No"}) { |r|
          if r == :default
            params = {}
            params = {"autotoken" => Store["autotoken"]} if Store["autotoken"] != nil
            erequest("logout", params) do |resp|
              if resp["code"] != 200
                UI.alert({:title => "Unexpected error occurred", :message => resp["errmsg"]}) { }
              else
                Store.delete("name")
                Store.delete("autotoken")
                $session = nil
                self.navigation.replace(WelcomeScreen.new)
              end
            end
          end
        }
      when 3 #debug
        dbg = ""
        dbg = "Platform: #{Elten.platform}\r\n"
        dbg += "Version: #{Elten.versioninfo}\r\n"
        dbg += "Elten Client ID: #{Store["appid"]}\r\n"
        dbg += "APNS Token: " + $apns_token.MSHexString + "\r\n"
        dbg += "User Interface Idiom: #{UIDevice.currentDevice.userInterfaceIdiom.to_s}\r\n"
        dbg += "Orientation: #{UIDevice.currentDevice.orientation.to_s}\r\n"
        dbg += "Name: #{UIDevice.currentDevice.name.to_s}\r\n"
        dbg += "System Version: #{UIDevice.currentDevice.systemVersion.to_s}\r\n"
        dbg += "Model: #{UIDevice.currentDevice.model}\r\n"
        dbg += "System name: #{UIDevice.currentDevice.systemName}\r\n"
        dbg += "buildVersion: #{UIDevice.currentDevice.buildVersion.to_s}\r\n"
        dbg += "Is Multitasking Supported: #{UIDevice.currentDevice.isMultitaskingSupported.to_s}\r\n"
        for v in ENV.keys
          dbg += v + ": " + ENV[v] + "\r\n"
        end
        UI.alert({:title => "Elten Debug Info", :message => dbg, :cancel => "Close"}) { }
      end
    end

    self.view.update_layout
  end
end
