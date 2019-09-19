# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class WelcomeScreen < UI::Screen
  def on_show
    self.navigation.hide_bar
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 25
    @background.background_color = :white
    self.view.add_child(@background)

    label = UI::Label.new
    label.margin = [10, 10, 5, 10]
    label.text = "Sign In to Elten"
    label.background_color = :red
    label.color = :white
    label.text_alignment = :center
    label.header = true
    @background.add_child(label)

    @login_field = UI::TextInput.new
    @login_field.height = 50
    @login_field.margin = [10, 5]
    @login_field.placeholder = "Login"
    @login_field.background_color = :green
    @login_field.color = :black
    @background.add_child(@login_field)

    @pass_field = UI::TextInput.new
    @pass_field.secure = true
    @pass_field.height = 50
    @pass_field.margin = [60, 5]
    @pass_field.placeholder = "Password"
    @pass_field.background_color = :red
    @pass_field.color = :black
    @background.add_child(@pass_field)

    button = UI::Button.new
    button.height = 50
    button.margin = [0, 0]
    button.title = "Submit"
    button.background_color = :blue
    button.color = :black
    @background.add_child(button)

    button.on(:tap) { login }

    # Autologin
    if Store["name"] != nil and Store["autotoken"] != nil
      erequest("login", {"name" => Store["name"], "token" => Store["autotoken"], "appid" => Store["appid"]}) do |rpl|
        if rpl["code"] != 200
          UI.alert({:title => "Autologin failed", :message => rpl["errmsg"], :cancel => "Close"}) { }
          Store.delete("autotoken")
        else
          $session = Elten_Session.new({"name" => rpl["name"], "token" => rpl["token"]})
          proceed
        end
      end
    end

    self.view.update_layout
  end

  def login(authcode = nil)
    logindata = {"name" => @login_field.text, "pass" => @pass_field.text, "appid" => Store["appid"]}
    logindata["authcode"] = authcode if authcode != nil
    erequest("login", logindata) do |rpl|
            if rpl["code"] != 200
        UI.alert({:title => "Login failed", :message => rpl["errmsg"], :cancel => "Close"}) { }
      else
        if rpl["required"] == "twofactor"
          twofactor
        else
          $session = Elten_Session.new({"name" => rpl["name"], "token" => rpl["token"]})
          UI.alert({:title => "Do you wish to setup autologin?", :message => "After enabling autologin, you would be no longer prompted for username and password everytime Elten is launched.", :default => "Yes", :cancel => "No"}) { |ind|
            if ind == :default
              erequest("autologin", {"action" => "register", "device" => UIDevice.currentDevice.name.to_s}) do |autrpl|
                                if autrpl["code"] != 200
                  UI.alert({:title => "Autologin verification failed", :message => rpl["errmsg"], :cancel => "Close"}) { }
                else
                  Store["name"] = $session.name
                  Store["autotoken"] = autrpl["autotoken"]
                end
              end
            end
          }
          proceed
        end
      end
    end
  end

  def twofactor
    @twofactries ||= 0
    @twofactries += 1
    if @twofactries > 3
      @pass_field.text = ""
      self.view.delete_child(@twofacbg)
      self.view.add_child(@background)
      @twofacbg = nil
      @twofactries = 0
      return
    end
    if @twofacbg == nil
      @twofacbg = UI::View.new
      @twofacbg.flex = 1
      @twofacbg.margin = 25
      @twofacbg.background_color = :white
      twofaclabel = UI::Label.new
      twofaclabel.height = 50
      twofaclabel.text = "Two-Factor Authentication"
      twofaclabel.header = true
      @twofacbg.add_child(twofaclabel)
      twofacdsc = UI::Label.new
      twofacdsc.height = 100
      twofacdsc.text = "The authentication code has been sent to the phone number associated with this account.\r\nEnter it below to proceed."
      @twofacbg.add_child(twofacdsc)
      @twofaccode = UI::TextInput.new
      @twofaccode.height = 50
      @twofaccode.placeholder = "Authentication code"
      @twofaccode.numbers = true
      @twofacbg.add_child(@twofaccode)
      @twofaccancel = UI::Button.new
      @twofaccancel.height = 50
      @twofaccancel.title = "Cancel"
      @twofacbg.add_child(@twofaccancel)
      @twofacbutton = UI::Button.new
      @twofacbutton.height = 50
      @twofacbutton.title = "Continue"
      @twofacbg.add_child(@twofacbutton)
      self.view.delete_child(@background)
      self.view.add_child(@twofacbg)
    end

    @twofaccancel.on(:tap) { self.navigation.replace(WelcomeScreen.new) }

    @twofacbutton.on :tap do
      if @twofaccode.text != ""
        login(@twofaccode.text)
        @twofaccode.text = ""
      end
    end
  end

  def proceed
    return if $session == nil # ignore if no session established
    forum_screen = ForumScreen.new
    messages_screen = MessagesScreen.new
main_screen=MainScreen.new
navigations=[UI::Navigation.new(forum_screen),UI::Navigation.new(messages_screen), UI::Navigation.new(main_screen)]
$app.tabbars(["Forum","Messages","More"], navigations)
#    self.navigation.replace(main_screen)
  end
end
