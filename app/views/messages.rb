# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class MessagesScreenTemplate < UI::Screen
  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

if defined?(task)!=nil and !self.navigation.screen.is_a?(TopicScreen)
@refresh=UI::Button.new
@refresh.height=20
@refresh.title="Refresh"
@refresh.on(:tap) {task}
@background.add_child(@refresh)
end

    @list = UI::List.new
    @list.margin = [5, 5]
    @list.height = 400
    @background.add_child(@list)

    @compose_button = UI::Button.new
    @compose_button.height = 50
    @compose_button.title = "Compose new message"
    @background.add_child(@compose_button)
  end
end

class MessagesScreen < MessagesScreenTemplate
  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = "Messages"
    @users = []


    update_users

  end

  def on_load
    super

    @maxid ||= 0

    @list.on :select do |opt, ind|
      conversations_screen = ConversationsScreen.new(@users[ind]["user"])
      self.navigation.push(conversations_screen)
    end

    @compose_button.on(:tap) { self.navigation.push(MessagesNewScreen.new) }

    self.view.update_layout
task(false)
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("messages/maxid", {"cat" => "users"},doUpdate) do |resp|
        if doUpdate and resp["code"] == 200 and resp["maxid"].to_i > @maxid
		@maxid=resp['maxid'].to_i
          update_users
          play("messages_update")
        end
      end
    end
  end

  def update_users
    erequest("messages/list", {"cat" => "users"}) do |resp|
            if resp["code"] != 200
        UI.alert({:title => "Error occurred", :message => resp["errmsg"]}) { }
      else
        @users = resp["users"]
        usr = []
        act = []
        resp["users"].each do |r|
          act.push({"Show profile" => Proc.new { |act, row| self.navigation.push(ProfileScreen.new(@users[row.row]["user"])) }})
          mdate = Time.at(r["date"].to_i)
          usr.push(((r["read"].to_i == 0 and r["last"] != $session.name) ? "(New): " : "") + r["user"] + "\r\n" + r["last"] + ": " + r["subj"] + "\r\n" + mdate.strftime("%Y-%m-%d %H:%M:%S"))
          @maxid = r["id"].to_i if (@maxid || 0) < r["id"].to_i
        end
        @list.data_source = usr
        @list.actions = act
      end
    end
  end
end

class ConversationsScreen < MessagesScreenTemplate
  def initialize(user = $session.name)
    @user = user
    super
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = "Conversations with " + @user

    if $msgtopictask != nil
      $msgtopictask.stop
      $msgtopictask = nil
    end

    update_conversations

  end

  def on_load
    super

    @maxid ||= 0

    @list.on :select do |opt, ind|
      topic_screen = TopicScreen.new(@user, @conversations[ind]["subj"])
      self.navigation.push(topic_screen)
    end

    @compose_button.on(:tap) { self.navigation.push(MessagesNewScreen.new(@user)) }

    self.view.update_layout
task(false)
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("messages/maxid", {"cat" => "conversations", "user" => @user},doUpdate) do |resp|
        if doUpdate and resp["code"] == 200 and resp["maxid"].to_i > @maxid
		@maxid=resp['maxid'].to_i
          update_conversations
          play("messages_update")
        end
      end
    end
  end

  def update_conversations
    @conversations = []

    erequest("messages/list", {"cat" => "conversations", "user" => @user},true) do |resp|
            if resp["code"] != 200
        UI.alert({:title => "Error occurred", :message => resp["errmsg"]}) { }
      else
        @conversations = resp["conversations"]
        cnv = []
        resp["conversations"].each do |r|
          mdate = Time.at(r["date"].to_i)
          cnv.push(((r["read"].to_i == 0 and r["last"] != $session.name) ? "(New): " : "") + ((r["subj"] != "") ? r["subj"] : "No Subject") + "\r\n" + r["last"] + "\r\n" + mdate.strftime("%Y-%m-%d %H:%M:%S"))
          @maxid = r["id"].to_i if (@maxid || 0) < r["id"].to_i
        end
        @list.data_source = cnv
      end
    end
  end
end

class TopicScreen < MessagesScreenTemplate
  def initialize(user, subj)
    @user = user
    @subj = subj
    super
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = @subj
    update_topic(true)
    task(false)
  end

  def on_load
    super

    @list.height = 300

    @list.on :select do |opt, ind|
      msg = @messages[ind]
      if msg["audio_url"] != nil and msg["audio_url"] != ""
        if msg["audio_url"] == @lasturl and $streamer.state != Player::StateNone and $streamer.position != $streamer.duration
          if $streamer.state == Player::StatePlaying
            $streamer.pause
          else
            $streamer.resume
          end
        else
          @lasturl = msg["audio_url"]
          $streamer.play(@lasturl)
        end
      end
    end

    @maxid ||= 0

    @reply = UI::TextInput.new
    @reply.margin = [0, 0]
    @reply.height = 50
    @reply.placeholder = "Your reply"
    @reply.enter { send }
    @background.add_child(@reply)

    @reply.on(:focus) { @background.scale(1, 0.5) }

    @reply.on(:blur) { @background.scale(1, 1) }

    @compose_button.on(:tap) { self.navigation.push(MessagesNewScreen.new(@user, @subj)) }
@compose_button.height=30

    @send = UI::Button.new
    @send.title = "Record audio message"
    @send.margin = [0, 0]
    @send.height = 50
    @background.add_child(@send)

    @send.on(:tap) {
if @reply.text!=""
send
else
      if @recording != nil
        tim = (tm = Time.now).to_i * 1000000 + tm.usec
        if (tim - @recording) < 10000
          recording_stop
          UI.alert(:title => "Information", :message => "Hold this button to record message, release it once record is completed.", :default => "Ok") { }
        else
          recording_stop
          recording_send
        end
      end
end
}

@send.on(:touchdown) { record_btn_hold if @reply.text==""}

@reply.on(:change) do
if @reply.text==""
@send.title="Record audio message"
else
@send.title="Send"
end
end

    self.view.update_layout
task(false)
  end

  def send
    if @reply.text != ""
      url = create_query("messages/send", {"to" => @user, "subj" => "RE: " + @subj})
      head = {"Content-Type" => "application/json"}
      Net.post(url, {:body => {"msg" => @reply.text}, :headers => head}) do |rsp|
	  if rsp.body.is_a?(Hash)
        if rsp.body["code"] != 200
          UI.alert({:title => "Error while sending your reply", :message => rsp.body["errmsg"]}) { }
        else
          update_topic
          @reply.text = ""
        end
      end
	  end
    end
  end

  def before_on_disappear
    if $streamer != nil
      $streamer.stop
      $streamer = nil
    end
    recording_stop if @recording != nil
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("messages/maxid", {"cat" => "messages", "user" => @user, "subj" => @subj},doUpdate) do |resp|
        if doUpdate and resp["code"] == 200 and resp["maxid"].to_i > @maxid
		@maxid=resp['maxid'].to_i
          update_topic
          play("messages_update")
        end
      end
      $msgtopictask = Task.after(5) { task }
    end
  end

  def update_topic(doScroll=false)
    @messages = []
    erequest("messages/list", {"cat" => "messages", "user" => @user, "subj" => @subj}) do |resp|
            if resp["code"] != 200
        UI.alert({:title => "Error occurred", :message => resp["errmsg"]}) { }
      else
        @messages = resp["messages"]
        msg = []
        resp["messages"].each do |r|
          $streamer = Player.new if r["audio_url"] != nil and r["audio_url"] != ""
          mdate = Time.at(r["date"].to_i)
          msg.push(r["sender"] + "\r\n" + r["message"] + "\r\n" + mdate.strftime("%Y-%m-%d %H:%M:%S"))
          @maxid = r["id"].to_i if (@maxid || 0) < r["id"].to_i
        end
        @list.data_source = msg
		if doScroll
          scroller = 0
          for i in 0...resp['messages'].size
		  scroller=i if resp['messages'][i]['read'].to_i==0 and resp['messages'][i]['sender']!=$session.name and scroller==0
		  end
          @list.scroll(scroller)
        end
      end
    end
  end

  def record_btn_hold
    if (Recorder.permitted?) == nil
      Recorder.request_permission(
        Proc.new {},
        Proc.new { recording_start },
        Proc.new { }
      )
    elsif Recorder.permitted?
      recording_start if @recording == false or @recording == nil
    end
  end

  def recording_start
    play("quickrecording_start")
    if @cancel == nil
      @cancel = UI::Button.new
      @cancel.title = "Cancel recording"
      @cancel.height = 120
      @cancel.on(:tap) { recording_stop }
    end
    @background.delete_child(@reply)
    @background.add_child(@cancel)
    @send.title = "Stop recording"
    @recording_file ||= ENV["TMPDIR"] + "/audiomessage.m4a"
    File.delete(@recording_file) if FileTest.exists?(@recording_file)
    AudioConfig.category_tospeaker = AudioConfig::CategoryPlayAndRecord
    @recorder = Recorder.new(@recording_file, Recorder::QualityMedium)
    UI.alert(:title => "Error", :message => "Cannot initialize recorder") { } if !@recorder.start
    @recording = (tm = Time.now).to_i * 1000000 + tm.usec
    self.view.update_layout
  end

  def recording_stop
    @recorder.stop
    AudioConfig.category = AudioConfig::CategoryAmbient
    @send.title = "Record Audio Message"
    @background.delete_child(@cancel)
@background.delete_child(@send)
    @background.add_child(@reply)
@background.add_child(@send)
    @recording = nil
    play("quickrecording_stop")
    self.view.update_layout
  end

  def recording_send
    @sbj = "RE: " + @subj
    @to = @user
    rece = File.get_data(@recording_file)

    url = create_query("messages/send", {"to" => @to, "subj" => @sbj, "src" => "-", "type" => "audio"})
    head = {"Content-Type" => "application/aac"}
    Net.post(url, {:body => rece, :headers => head}) do |rsp|
	if rsp.body.is_a?(Hash)
      if rsp.body["code"] != 200
        UI.alert({:title => "Error while sending your reply", :message => rsp.body["errmsg"]}) { }
      else
        update_topic
      end
    end
  end
  end
end

class MessagesNewScreen < UI::Screen
  def initialize(to = nil, subj = nil)
    @to = to
    @subj = subj
    super
  end

  def on_show
    self.navigation.hide_bar if !self.navigation.bar_hidden?
    self.navigation.title = "New message"
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    label = UI::Label.new
    label.text = "New message"
    label.text = "New message"
    if @subj != nil
      label.text += " in thread #{@subj}"
    elsif @to != nil
      label.text += " to #{@to}"
    end
    label.height = 50
    label.header = true
    @background.add_child(label)

    if @to == nil
      @receiver_field = UI::TextInput.new
      @receiver_field.height = 50
      @receiver_field.placeholder = "Receiver"
      @background.add_child(@receiver_field)
      @receiver_field.on(:focus) { @background.scale(1, 0.5) }
      @receiver_field.on(:blur) { @background.scale(1, 0.5) }
    end

    if @subj == nil
      @subject_field = UI::TextInput.new
      @subject_field.height = 50
      @subject_field.placeholder = "Subject"
      @background.add_child(@subject_field)
      @subject_field.on(:focus) { @background.scale(1, 0.5) }
      @subject_field.on(:blur) { @background.scale(1, 0.5) }
    end

    @message_view = UI::Text.new
    @message_view.height = 250
    @message_view.height += 50 if @subj != nil
    @message_view.height += 50 if @to != nil
    @message_view.placeholder = "Your message"
    @background.add_child(@message_view)
    @message_view.on(:focus) { @background.scale(1, 0.5) }
    @message_view.on(:blur) { @background.scale(1, 0.5) }

    @record = UI::Button.new
    @record.height = 50
    @record.title = "Record message"
    @background.add_child(@record) if (Recorder.permitted?) != false
    @record.on(:tap) { record_btn }

    @cancel = UI::Button.new
    @cancel.title = "Cancel"
    @cancel.height = 50
    @background.add_child(@cancel)

    @cancel.on(:tap) do
      if @message_view.text == ""
        self.navigation.pop
      else
        UI.alert({:title => "Are you sure you want to cancel the compossing of new message?", :message => "All the typed text will be lost.", :cancel => "No", :default => "Yes"}) { |ind|
          self.navigation.pop if ind == :default
        }
      end
    end

    @send = UI::Button.new
    @send.title = "Send"
    @send.height = 50
    @background.add_child(@send)

    @send.on(:tap) do
      if @recording == nil
        if (@subj != nil or @subject_field.text != "") and (@to != nil or @receiver_field.text != "") and @message_view.text != ""
          @sbj = "RE: " + @subj if @subj != nil
          @sbj = @subject_field.text if @subj == nil
          @to = @receiver_field.text if @to == nil
          url = create_query("messages/send", {"to" => @to})
          head = {"Content-Type" => "application/json"}
          body = {"subj" => @sbj, "msg" => @message_view.text}
          Net.post(url, {:body => body, :headers => head}) do |rsp|
		  if rsp.body.is_a?(Hash)
            if rsp.body["code"] != 200
              UI.alert({:title => "Unexpected error occurred while sending this message", :message => rsp.body["errmsg"]}) { }
            else
              self.navigation.pop
            end
          end
		  end
        end
      else
        recording_send
      end
    end

    self.view.update_layout
  end

  def record_btn
    if (Recorder.permitted?) == nil
      Recorder.request_permission(
        Proc.new { @background.delete_child(@record) },
        Proc.new { recording_start },
        Proc.new { }
      )
    elsif Recorder.permitted?
      if @recording == false or @recording == nil
        recording_start
      else
        recording_stop
      end
    end
  end

  def before_on_disappear
    if $streamer != nil
      $streamer.stop
      $streamer = nil
    end
    recording_stop if @recording != nil
  end

  def recording_start
    @background.delete_child(@play) if @play != nil
    @background.delete_child(@message_view)
    play("recording_start")
    @record.title = "Stop recording"
    @recording_file ||= ENV["TMPDIR"] + "/audiomessage.m4a"
    File.delete(@recording_file) if FileTest.exists?(@recording_file)
    AudioConfig.category = AudioConfig::CategoryPlayAndRecord
    @recorder = Recorder.new(@recording_file)
    UI.alert(:title => "Error", :message => "Cannot initialize recorder") { } if !@recorder.start
    @recording = true
    self.view.update_layout
  end

  def recording_stop
    @recorder.stop
    $streamer ||= Player.new
    AudioConfig.category = AudioConfig::CategoryAmbient
    @record.title = "Record again"
    if @play == nil
      @play = UI::Button.new
      @play.title = "Play recorded message"
      @play.height = 40
      @play.on(:tap) { $streamer.play(@recording_file) }
    end
    if @undo == nil
      @undo = UI::Button.new
      @undo.height = 40
      @undo.title = "Return to text editor"
      @undo.on(:tap) do
        @background.delete_child(@play)
        @background.delete_child(@undo)
        @background.delete_child(@cancel)
        @background.delete_child(@send)
        @background.add_child(@message_view)
        @background.add_child(@cancel)
        @background.add_child(@send)
        @recording = nil
      end
    end
    @background.add_child(@play)
    @background.add_child(@undo)
    play("recording_stop")
    @recording = false
    self.view.update_layout
  end

  def recording_send
    @sbj = "RE: " + @subj if @subj != nil
    @sbj = @subject_field.text if @subj == nil
    @to = @receiver_field.text if @to == nil
    rece = File.get_data(@recording_file)

    url = create_query("messages/send", {"to" => @to, "subj" => @sbj, "src" => "-", "type" => "audio"})
    head = {"Content-Type" => "application/aac"}
    Net.post(url, {:body => rece, :headers => head}) do |rsp|
	if rsp.body.is.a?(Hash)
      if rsp.body["code"] != 200
        UI.alert({:title => "Error while sending your reply", :message => rsp.body["errmsg"]}) { }
      else
        self.navigation.pop
      end
    end
	end
  end
end
