# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class ProfileScreen < UI::Screen
  def initialize(user)
    @user = user
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = @user
  end

  def on_load
    $screen = self

    background = UI::View.new
    background.flex = 1
    background.margin = 25
    background.background_color = :white
    self.view.add_child(background)

    message = UI::Button.new
    message.title = "Send message"
    message.height = 50
    message.on(:tap) { self.navigation.push(MessagesNewScreen.new(@user)) }
    background.add_child(message)

    Net.get(create_query("profile", {"user" => @user})) do |rsp|
      resp = rsp.body
      if resp["code"] == 200
        if resp["status"] != ""
          status = UI::Label.new
          status.height = 80
          status.text = resp["status"]
          background.add_child(status)
        end
        if resp["avatar"] != nil
          $streamer = Player.new
          avatar = UI::Button.new
          avatar.height = 50
          avatar.title = resp["avatar"]
          avatar.on :tap do
            if $streamer.state == Player::StateNone or $streamer.duration == $streamer.position
              $streamer.play(resp["avatar"])
            elsif $streamer.state == Player::Playing
              $streamer.pause
            else
              $streamer.resume
            end
          end
          background.add_child(avatar)
        end
        if resp["fullname"] != "" and resp["fullname"] != nil
          fullname = UI::Label.new
          fullname.height = 20
          fullname.text = resp["fullname"]
          background.add_child(fullname)
        end
        if resp["gender"] != nil
          gender = UI::Label.new
          gender.height = 20
          gender.text = "Gender: " + ((resp["gender"].to_i == 1) ? "male" : "female")
          background.add_child(gender)
        end
        if resp["age"] != nil and resp["age"] > 0
          age = UI::Label.new
          age.height = 20
          age.text = "Age: " + resp["age"].to_s
          background.add_child(age)
        end
        if resp["visitingcard"] != nil
          vchead = UI::Label.new
          vchead.header = true
          vchead.height = 50
          vchead.text = "Visitingcard"
          background.add_child(vchead)
          vc = UI::StaticText.new
          vc.height = 150
          vc.text = resp["visitingcard"]
          background.add_child(vc)
        end
        self.view.update_layout
      else
        UI.alert(:title => "Error", :message => resp["errmsg"]) { }
      end
    end

    self.view.update_layout
  end

  def before_on_disappear
    if $streamer != nil
      $streamer.stop if $streamer.error == ""
      $streamer = nil
    end
  end
end
