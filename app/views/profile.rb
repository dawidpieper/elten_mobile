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
    message.title = _("Send message")
    message.height = self.view.height * 0.1
    message.on(:tap) { self.navigation.push(MessagesNewScreen.new(@user)) }
    background.add_child(message)

    erequest("profile", { "user" => @user }) do |resp|
      if resp["code"] == 200
        if resp["status"] != ""
          status = UI::Label.new
          status.height = self.view.height * 0.2
          status.text = resp["status"]
          background.add_child(status)
        end
      end
      if resp["fullname"] != "" and resp["fullname"] != nil
        fullname = UI::Label.new
        fullname.height = self.view.height * 0.05
        fullname.text = resp["fullname"]
        background.add_child(fullname)
      end
      if resp["gender"] != nil
        gender = UI::Label.new
        gender.height = self.view.height * 0.05
        gender.text = "#{_("Gender")}: " + ((resp["gender"].to_i == 1) ? _("male") : _("female"))
        background.add_child(gender)
      end
      if resp["age"] != nil and resp["age"] > 0
        age = UI::Label.new
        age.height = self.view.height * 0.05
        age.text = "#{_("Age")}: " + resp["age"].to_s
        background.add_child(age)
      end
      if resp["visitingcard"] != nil
        vchead = UI::Label.new
        vchead.header = true
        vchead.height = self.view.height * 0.1
        vchead.text = _("Visitingcard")
        background.add_child(vchead)
        vc = UI::StaticText.new
        vc.height = self.view.height * 0.3
        vc.text = resp["visitingcard"]
        background.add_child(vc)
        self.view.update_layout
      else
        UI.alert(:title => _("Error"), :message => resp["errmsg"]) { }
      end
    end

    self.view.update_layout
  end

  def before_on_disappear
  end
end
