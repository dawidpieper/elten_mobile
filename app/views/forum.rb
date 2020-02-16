# -*- coding: utf-8 -*-
# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

# Screen template to further usage
class ForumScreenTemplate < UI::Screen
  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    if defined?(task) != nil and !self.navigation.screen.is_a?(PostsScreen)
      @refresh = UI::Button.new
      @refresh.height = self.view.height * 0.03
      @refresh.title = _("Refresh")
      @refresh.on(:tap) {
        $forumcachetime = 0
        update
      }
      @background.add_child(@refresh)
    end

    @list = UI::List.new
    @list.margin = [5, 5]
    @list.height = self.view.height * 0.8
    @background.add_child(@list)


  end

  def getcache(must = false, &block)
    if ($forumcachetime || 0) < Time.now.to_i - 30 || must
      erequest("forum/struct", { "cat" => "groups", "listgroups" => "joined" }, true) do |resp|
        if resp.is_a?(Hash)
          if resp["code"] != 200
            UI.alert({ :title => _("Error occurred"), :message => resp["errmsg"] }) { }
          else
            @groups = []
            resp["groups"].values.each { |g| @groups.push(g) if g["open"] == 1 or g["public"] == 1 or g["role"] == 1 or g["role"] == 2 }
            @forums = resp["forums"].values
            @threads = resp["threads"].values
            @groups.sort! { |a, b| a["id"] <=> b["id"] }
            @forums.sort! { |a, b| a["pos"] <=> b["pos"] }
            @threads.sort! { |a, b| b["lastupdate"] <=> a["lastupdate"] }
            $forumcache = [@groups, @forums, @threads]
            $forumcachetime = Time.now.to_i
            block.call if block != nil
          end
        end
      end
    elsif $forumcache.is_a?(Array)
      @groups, @forums, @threads = $forumcache
      block.call if block != nil and @groups != nil and @forums != nil and @threads != nil
    end
  end
end

class ForumScreen < ForumScreenTemplate
  def initialize(type = 0)
    @type = type
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = "Forum"
    @sgroups = []
    update_groups
    @maxid = 0
  end

  def on_load
    super

    @list.on :select do |opt, ind|
      if (ind > 0 or @type > 0) and ind <= @sgroups.size
        d = ind
        d -= 1 if @type == 0
        if @sgroups[d]["public"] == 1 or @sgroups[d]["role"] == 1 or @sgroups[d]["role"] == 2
          group_screen = GroupScreen.new(@sgroups[d]["id"], @sgroups[d]["name"])
          self.navigation.push(group_screen)
        end
      elsif ind == 0
        threads_screen = ThreadsScreen.new("_followed", "Followed Threads")
        self.navigation.push(threads_screen)
      else
        self.navigation.push(ForumScreen.new(ind - @sgroups.size))
      end
    end
    self.view.update_layout
    task(false)
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("forum/maxid", {}, doUpdate) do |resp|
        if resp["code"] == 200 and (@maxid || 0) < resp["maxid"].to_i
          @maxid = resp["maxid"].to_i
          if doUpdate
            update_groups
            play("forum_update")
          end
        end
      end
    end
  end

  def update
    update_groups
  end

  def update_groups
    getcache do
      @sgroups = []
      @groups.each { |g|
        case @type
        when 0
          @sgroups.push(g) if g["role"] == 1 or g["role"] == 2 or g["recommended"] == 1
        when 1
          @sgroups.push(g) if g["open"] == 1
        when 2
          @sgroups.push(g) if g["open"] == 1 || g["public"] == 1
        when 3
          @sgroups.push(g) if g["role"] == 5
        end
      }
      grp = []
      acs = []
      @sgroups.each do |r|
        grp.push(r["name"] + "\n#{_("Forums")}: " + r["cnt_forums"].to_s + "\n#{_("Threads")}: " + r["cnt_threads"].to_s + "\n#{_("Posts")}: " + r["cnt_posts"].to_s + "\n#{_("New")}: " + (r["cnt_posts"].to_i - r["cnt_readposts"].to_i).to_s)
        a = { _("Members") => Proc.new { |opt, ind| d = ind.row; d -= 1 if @type == 0; navigation.push(MembersScreen.new(@sgroups[d])) } }
        k = nil
        if r["founder"] != $session.name and (r["role"] == 1 or r["role"] == 2)
          k = _("Leave")
        elsif r["open"] == 1 and r["public"] == 1 and r["role"] == 0
          k = _("Join")
        elsif r["role"] == 5
          k = _("Accept invitation")
        elsif r["role"] == 0 and r["open"] == 0
          k = _("Request")
        end
        a[k] = Proc.new { |opt, ind| chrole(ind) } if k != nil
        acs.push(a)
      end
      foll_threads = 0
      foll_posts = 0
      foll_readposts = 0
      @threads.each { |t|
        if t["followed"] == 1
          foll_threads += 1
          foll_posts += t["cnt_posts"].to_i
          foll_readposts += t["cnt_readposts"].to_i
        end
      }
      if self.navigation.screen == self
        @list.update_begin
        h = 0
        if @type == 0
          @list.edit(0, _("Followed threads")+"\n#{_("Threads")}: #{foll_threads.to_s}\n#{_("Posts")}: #{foll_posts.to_s}\n#{_("New")}: #{(foll_posts.to_i - foll_readposts.to_i).to_s}")
          h = 1
        end
        for i in 0...grp.size
          @list.edit(h + i, grp[i], acs[i])
        end
        if @type == 0
          e = h + grp.size
          @list.edit(e, _("All groups"))
          @list.edit(e + 1, _("Open groups"))
          @list.edit(e + 2, _("Waiting invitations"))
        end
        @list.update_end
        self.view.update_layout
      end
    end
  end

  def chrole(row)
    ind = row.row
    ind -= 1 if @type == 0
    g = @sgroups[ind]
    ac = _("join")
    ac = _("leave") if g["role"] == 1 or g["role"] == 2
    s = _("Are you sure you want to join ")
    s = _("Are you sure you want to leave ") if ac == "leave"
    s = _("Are you sure you want to request to join ") if g["open"] == 0
    s += "\"" + g["name"] + "\"?"
    UI.alert(:title => "Group membership", :message => s, :default => "Yes", :cancel => "No") { |n|
      if n == :default
        erequest("forum/groups", { "ac" => ac, "groupid" => g["id"].to_s }) { |rsp|
          if rsp.is_a?(Hash)
            if rsp["code"] != 200
              UI.alert(:title => _("Error"), :message => rsp["errmsg"], :default => "Cancel") { }
            else
              $forumcachetime = 0
              update_groups
            end
          end
        }
      end
    }
  end
end

class MembersScreen < UI::Screen
  def initialize(group)
    @group = group
  end

  def on_show
    self.navigation.title = _("Members of")+" #{@group["name"]}"
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    @list = UI::List.new
    @list.height = self.view.height
    @background.add_child(@list)

    erequest("forum/groups", { "ac" => "members", "groupid" => @group["id"].to_s }) { |rsp|
      if rsp.is_a?(Hash)
        if rsp["code"] != 200
          UI.alert(:title => _("Error"), :message => rsp["errmsg"], :default => "Cancel") { }
        else
          @members = []
          lst = []
          for m in rsp["members"]
            o = m["user"]
            o += " (#{_("moderator")})" if m["role"] == 2 and @group["founder"] != m["user"]
            o += " (#{_("administrator")})" if @group["founder"] == m["user"]
            o += " (#{_("invited")})" if m["role"] == 5
            o += " (#{_("waiting")})" if m["role"] == 4
            o += " (#{_("banned")})" if m["role"] == 3
            lst.push(o)
            @members.push(m["user"])
          end
          @list.update_begin
          for i in 0...lst.size
            @list.edit(i, lst[i])
          end
          @list.update_end
          @list.on(:select) { |opt, ind| navigation.push(ProfileScreen.new(@members[ind])) }
        end
      end
    }
  end
end

class GroupScreen < ForumScreenTemplate
  def initialize(id = 1, name = "")
    @id = id
    @name = name
    super
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = @name
    @sforums = []
    update_forums
    @maxid = 0
  end

  def on_load
    super

    @list.on :select do |opt, ind|
      threads_screen = ThreadsScreen.new(@sforums[ind]["id"], @sforums[ind]["name"])
      self.navigation.push(threads_screen)
    end
    self.view.update_layout
    task(false)
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("forum/maxid", {}, doUpdate) do |resp|
        if resp["code"] == 200 and (@maxid || 0) < resp["maxid"].to_i
          @maxid = resp["maxid"].to_i
          if doUpdate
            update_forums
            play("forum_update")
          end
        end
      end
    end
  end

  def update
    update_forums
  end

  def update_forums
    getcache do
      @sforums = []
      @forums.each { |f| @sforums.push(f) if f["groupid"].to_i == @id.to_i }
      frm = []
      @sforums.each do |r|
        frm.push(r["name"] + "\n#{_("Threads")}: " + r["cnt_threads"].to_s + "\n#{_("Posts")}: " + r["cnt_posts"].to_s + "\n#{_("New")}: " + (r["cnt_posts"].to_i - r["cnt_readposts"].to_i).to_s)
      end
      if self.navigation.screen == self
        @list.update_begin
        for i in 0...frm.size
          @list.edit(i, frm[i])
        end
        @list.update_end
        self.view.update_layout
      end
    end
  end
end

class ThreadsScreen < ForumScreenTemplate
  def initialize(id = 1, name = "")
    @id = id
    @name = name
    @type = 0
    super
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = @name
    @sthreads = []
    update_threads
    if $frmpoststask != nil
      $frmpoststask.stop
      $frmpoststask = nil
    end
    @maxid = 0
  end

  def on_load
    super

    @list.on :select do |opt, ind|
      $forumcachetime = 0 if @sthreads[ind]["cnt_readposts"] != @sthreads[ind]["cnt_posts"]
      posts_screen = PostsScreen.new(@sthreads[ind]["id"], @sthreads[ind]["name"])
      self.navigation.push(posts_screen)
    end

    @newbutton = UI::Button.new
    @newbutton.title = _("New thread")
    @newbutton.height = self.view.height * 0.1
    @background.add_child(@newbutton)

    @newbutton.on :tap do
      newthread_screen = ThreadsNewScreen.new(@id, @type)
      self.navigation.push(newthread_screen)
      task(false)
    end

    self.view.update_layout
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("forum/maxid", {}, doUpdate) do |resp|
        if resp["code"] == 200 and (@maxid || 0) < resp["maxid"].to_i
          @maxid = resp["maxid"].to_i
          if doUpdate
            update_threads
            play("forum_update")
          end
        end
      end
    end
  end

  def update
    update_threads
  end

  def update_threads
    getcache do
      @type = 0
      @forums.each { |f| @type = f["type"] if f["id"] == @id }
      if (@type == 1 and (Recorder.permitted?) == false) or @type == -1 or @id[0..0] == "_"
        @background.delete_child(@newbutton)
        self.view.update_layout
      end
      @sthreads = []
      thr = []
      acs = []
      @threads.each { |r| @sthreads.push(r.clone) if r["forumid"] == @id or (@id == "_followed" and r["followed"] == 1) }
      @sthreads.each do |r|
        acs.push({})
        s = _("Follow thread")
        s = _("Unfollow thread") if r["followed"] == 1
        acs.last[s] = Proc.new { |opt, ind| chfollow(ind) }
        thr.push(((r["cnt_readposts"].to_i < r["cnt_posts"].to_i) ? "(#{_("New")}): " : "") + r["name"] + "\n#{_("Posts")}: " + r["cnt_posts"].to_s + "\n#{_("New")}: " + (r["cnt_posts"].to_i - r["cnt_readposts"].to_i).to_s)
      end
      if self.navigation.screen == self
        @list.update_begin
        for i in 0...thr.size
          @list.edit(i, thr[i], acs[i])
        end
        @list.update_end
        self.view.update_layout
      end
    end
  end

  def chfollow(row)
    ind = row.row
    $forumcachetime = 0
    erequest("forum/follow", { "cat" => "thread", "threadid" => @sthreads[ind]["id"].to_s, "ac" => (@sthreads[ind]["followed"] == 1) ? "unfollow" : "follow" }) do |resp|
      if resp["code"] == 200
        @sthreads[ind]["followed"] = (@sthreads[ind]["followed"] == 0) ? 1 : 0
        @list.actions[ind] = { (@sthreads[ind]["followed"] == 0) ? "Follow thread" : "Unfollow thread" => Proc.new { |opt, ind| chfollow(ind) } }
      else
        UI.alert(:title => _("Error"), :message => resp["errmsg"]) { }
      end
    end
  end
end

class ThreadsNewScreen < UI::Screen
  def initialize(forum, type = l0)
    @forum = forum
    @type = type
  end

  def on_show
    $forumcachetime = 0
    self.navigation.hide_bar if !self.navigation.bar_hidden?
    self.navigation.title = _("New Thread")
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    label = UI::Label.new
    label.text = _("New thread")
    label.height = self.view.height * 0.1
    label.header = true
    @background.add_child(label)

    @title_field = UI::TextInput.new
    @title_field.height = self.view.height * 0.2
    @title_field.placeholder = _("Title")
    @background.add_child(@title_field)

    @title_field.on :focus do
      @background.scale(1, 0.5)
    end

    @title_field.on :focus do
      @background.scale(0.3, 1)
    end

    if @type == 0
      post_view = UI::Text.new
      post_view.height = self.view.height * 0.5
      post_view.placeholder = _("Post")
      @background.add_child(post_view)
      post_view.on(:focus) { @background.scale(1, 0.5) }
      post_view.on(:blur) { @background.scale(1, 1) }
    else
      @record = UI::Button.new
      @record.title = _("Record post")
      @record.height = self.view.height * 0.2
      @background.add_child(@record)
      @record.on(:tap) { postrecbtn }
      $streamer = Player.new
    end

    cancel_button = UI::Button.new
    cancel_button.title = _("Cancel")
    cancel_button.height = self.view.height * 0.1
    @background.add_child(cancel_button)

    cancel_button.on :tap do
      if (@type == 0 and post_view.text == "") or (@type == 1 and @recording != false)
        self.navigation.pop
      else
        UI.alert({ :title => _("Are you sure you want to cancel the creation of new thread?"), :message => _("All the typed text will be lost."), :cancel => _("No"), :default => _("Yes") }) { |ind|
          self.navigation.pop if ind == :default
        }
      end
    end

    if @type == 0
      post_button = UI::Button.new
      post_button.title = _("Create thread")
      post_button.height = self.view.height * 0.1
      @background.add_child(post_button)

      post_button.on :tap do
        if @title_field.text != "" and post_view.text != ""
          url = create_query("forum/edit", { "ac" => "add", "forum" => @forum.to_s, "threadid" => "new" })
          head = { "Content-Type" => "application/json" }
          body = { "threadname" => @title_field.text, "post" => post_view.text }
          Net.post(url, { :body => body, :headers => head }) do |rsp|
            if rsp.body.is_a?(Hash)
              if rsp.body["code"] != 200
                UI.alert({ :title => _("Unexpected error occurred while creating thread"), :message => rsp.body["errmsg"] }) { }
              else
                self.navigation.pop
              end
            end
          end
        end
      end
    end
  end

  def before_on_disappear
    recording_stop if @recording == true
    $streamer.stop if $streamer != nil
  end

  def postrecbtn
    if (Recorder.permitted?) == nil
      Recorder.request_permission(
        Proc.new { @background.delete_child(@record) },
        Proc.new { recording_start },
        Proc.new { }
      )
    elsif (Recorder.permitted?) == true
      if @recording == false or @recording == nil
        recording_start
      else
        recording_stop
      end
    end
  end

  def recording_start
    @background.delete_child(@play) if @play != nil
    @background.delete_child(@sendrec) if @sendrec != nil
    play("recording_start")
    @record.title = _("Stop recording")
    @recording_file ||= ENV["TMPDIR"] + "/audiopost.m4a"
    File.delete(@recording_file) if FileTest.exists?(@recording_file)
    AudioConfig.category = AudioConfig::CategoryPlayAndRecord
    @recorder = Recorder.new(@recording_file)
    @recorder.start
    @recording = true
    self.view.update_layout
  end

  def recording_stop
    @recorder.stop
    AudioConfig.category = AudioConfig::CategoryAmbient
    @record.title = _("Record again")
    @play = UI::Button.new
    @play.title = _("Play recorded post")
    @play.height = self.view.height * 0.08
    @background.add_child(@play)
    @play.on(:tap) { $streamer.play(@recording_file) }
    @sendrec = UI::Button.new
    @sendrec.title = _("Send")
    @sendrec.height = self.view.height * 0.12
    @background.add_child(@sendrec)
    @sendrec.on(:tap) { recording_send }
    play("recording_stop")
    @recording = false
    self.view.update_layout
  end

  def recording_send
    @record.title = _("Sending...")
    @record.enabled = false
    @sendrec.enabled = false
    rece = File.get_data(@recording_file)

    url = create_query("forum/edit", { "ac" => "add", "threadid" => "new", "forum" => @forum.to_s, "src" => "-", "type" => "audio", "threadname" => @title_field.text })
    head = { "Content-Type" => "application/aac" }
    Net.post(url, { :body => rece, :headers => head }) do |rsp|
      if rsp.body.is_a?(Hash)
        if rsp.body["code"] != 200
          UI.alert({ :title => _("Error while sending your reply"), :message => rsp.body["errmsg"] }) { }
        else
          self.navigation.pop
        end
      end
    end
  end
end

class PostsScreen < ForumScreenTemplate
  def initialize(id = 1, name = "")
    @id = id
    @name = name
    super
  end

  def on_show
    self.navigation.show_bar if self.navigation.bar_hidden?
    self.navigation.title = @name
    @posts ||= []
    update_posts(true)
    @maxid ||= 0
    if $streamer != nil
      $streamer.stop
      $streamer = nil
    end
  end

  def on_load
    super

    @list.height = self.view.height * 0.7

    @list.on :select do |opt, ind|
      if @posts != nil
        post = @posts[ind]
        if post["audio_url"] != nil and post["audio_url"] != ""
          if post["audio_url"] == @lasturl and $streamer.state != Player::StateNone and $streamer.position != $streamer.duration
            if $streamer.state == Player::StatePlaying
              $streamer.pause
            else
              $streamer.resume
            end
          else
            @lasturl = post["audio_url"]
            $streamer.play(@lasturl)
          end
        else
          navigation.push(PostScreen.new(post))
        end
      end
    end

    self.view.update_layout
    task(false)
  end

  def before_on_disappear
    if $streamer != nil
      $streamer.stop
      $streamer = nil
    end
    recording_stop if @recording == true
    if $frmpoststask != nil
      $frmpoststask.stop
      $frmpoststask = nil
    end
  end

  def task(doUpdate = true)
    if self.navigation.screen == self
      erequest("forum/thread_maxid", { "thread" => @id.to_s }, true) do |resp|
        if resp["code"] == 200 and (@maxid || 0) < resp["maxid"].to_i and doUpdate
          update_posts
          play("forum_update")
        end
      end
      $frmpoststask = Task.after(5) { task }
    end
  end

  def update
    update_posts
  end

  def update_posts(doScroll = false)
    erequest("forum/posts", { "thread" => @id.to_s }, true) do |resp|
      if self.navigation.screen == self
        if resp != nil
          if resp["code"] != 200
            UI.alert({ :title => _("Error occurred"), :message => resp["errmsg"] }) { }
          else
            @posts = resp["posts"]
            pst = []
            act = []
            cnt = 0
            resp["posts"].each do |r|
              act.push({ _("Show profile") => Proc.new { |act, row| self.navigation.push(ProfileScreen.new(@posts[row.row]["author"])) } })
              if $streamer == nil and r["audio_url"] != nil and r["audio_url"] != ""
                $streamer = Player.new
                if @record == nil and (Recorder.permitted?) != false
                  @record = UI::Button.new
                  @record.title = _("Record Post")
                  @record.margin = [5, 5]
                  @record.height = self.view.height * 0.05
                  @background.add_child(@record)
                  @record.on(:tap) { record_btn }
                end
                self.view.update_layout
              end
              cnt += 1
              @maxid = r["id"].to_i if (@maxid || 0) < r["id"].to_i
              pst.push(((cnt <= resp["readposts"].to_i) ? "" : "(NEW): ") + r["author"] + "\n" + r["post"] + "\n" + r["date"])
            end
            @list.update_begin
            for i in 0...pst.size
              @list.edit(i, pst[i], act[i])
            end
            @list.update_end
            if doScroll
              scroller = resp["readposts"].to_i - 1
              scroller = 0 if scroller < 0
              @list.scroll(scroller)
            end
          end
          if @reply == nil and $streamer == nil
            @reply = UI::Text.new
            @reply.editable = true
            @reply.margin = [0, 0]
            @reply.height = self.view.height * 0.1
            @reply.width = 400
            @reply.placeholder = _("Your reply")
            @background.add_child(@reply)

            @reply.on(:focus) { @background.scale(1, 0.5) }

            @reply.on(:blur) { @background.scale(1, 1) }

            @button = UI::Button.new
            @button.title = _("Post reply")
            @button.margin = [0, 0]
            @button.height = self.view.height * 0.03
            @background.add_child(@button)

            @button.on :tap do
              url = create_query("forum/edit", { "ac" => "add", "threadid" => @id.to_s })
              head = { "Content-Type" => "application/json" }
              Net.post(url, { :body => { "post" => @reply.text }, :headers => head }) do |rsp|
                if rsp.body.is_a?(Hash)
                  if rsp.body["code"] != 200
                    UI.alert({ :title => _("Error while sending your reply"), :message => rsp.body["errmsg"] }) { }
                  else
                    update_posts
                    @reply.text = ""
                  end
                end
              end
            end
            self.view.update_layout
          end
        end
      end
    end
  end

  def record_btn
    if (Recorder.permitted?) == nil
      Recorder.request_permission(
        Proc.new { @background.delete_child(@record) },
        Proc.new { recording_start },
        Proc.new { }
      )
    else (Recorder.permitted?) == true
      if @recording == false or @recording == nil
      recording_start
    else
      recording_stop
    end     end
  end

  def recording_start
    @background.delete_child(@play) if @play != nil
    @background.delete_child(@sendrec) if @sendrec != nil
    play("recording_start")
    @record.title = _("Stop recording")
    @recording_file ||= ENV["TMPDIR"] + "/audiopost.m4a"
    File.delete(@recording_file) if FileTest.exists?(@recording_file)
    AudioConfig.category = AudioConfig::CategoryPlayAndRecord
    @recorder = Recorder.new(@recording_file)
    UI.alert(:title => _("Error"), :message => "Cannot initialize recorder") { } if !@recorder.start
    @recording = true
    self.view.update_layout
  end

  def recording_stop
    @recorder.stop
    AudioConfig.category = AudioConfig::CategoryAmbient
    @record.title = _("Record again")
    @play = UI::Button.new
    @play.title = _("Play recorded post")
    @play.height = self.view.height * 0.05
    @background.add_child(@play)
    @play.on(:tap) { $streamer.play(@recording_file) }
    @sendrec = UI::Button.new
    @sendrec.title = _("Send")
    @sendrec.height = self.view.height * 0.07
    @background.add_child(@sendrec)
    @sendrec.on(:tap) { recording_send }
    play("recording_stop")
    @recording = false
    self.view.update_layout
  end

  def recording_send
    @record.title = _("Sending...")
    @record.enabled = false
    @background.delete_child(@sendrec)
    rece = File.get_data(@recording_file)

    url = create_query("forum/edit", { "ac" => "add", "threadid" => @id.to_s, "src" => "-", "type" => "audio" })
    head = { "Content-Type" => "application/aac" }
    Net.post(url, { :body => rece, :headers => head }) do |rsp|
      @record.title = _("Record post")
      @record.enabled = true
      if rsp.body.is_a?(Hash)
        if rsp.body["code"] != 200
          @background.add_child(@sendrec)
          UI.alert({ :title => _("Error while sending your reply"), :message => rsp.body["errmsg"] }) { }
        else
          update_posts
          @background.delete_child(@sendrec)
          @background.delete_child(@play)
        end
      end
    end
  end
end

class PostScreen < UI::Screen
  def initialize(post)
    @post = post
  end

  def on_show
    navigation.title = "#{_("Post by")} #{@post["author"]}"
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    pst = UI::StaticText.new
    pst.height = self.view.height
    pst.text = @post["post"]
    @background.add_child(pst)

    self.view.update_layout
  end
end
