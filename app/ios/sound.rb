module EltenAPI
  module Sound
    def play(voice, volume = 100, rate = 100)
      Task.background do
        soundURL = NSBundle.mainBundle.URLForResource("audio/" + voice, withExtension: "m4a")
        audioPlayer = AVAudioPlayer.alloc
        audioPlayer.initWithContentsOfURL(soundURL, error: nil)
        audioPlayer.volume = volume.to_f / 100.0
        audioPlayer.rate = rate.to_f / 100.0
        audioPlayer.prepareToPlay
        audioPlayer.play
        sleep(0.1) while audioPlayer.isPlaying
      end
    end

    class AudioConfig
      CategoryAmbient = AVAudioSessionCategoryAmbient
      CategoryPlayAndRecord = AVAudioSessionCategoryPlayAndRecord
      OptionDefaultToSpeaker = AVAudioSessionCategoryOptionDefaultToSpeaker
      def self.category
        AVAudioSession.sharedInstance.category
      end
      def self.category=(c)
        err_ptr = Pointer.new(:object)
        AVAudioSession.sharedInstance.setCategory(c, error: err_ptr)
        AVAudioSession.sharedInstance.setActive(true, error: err_ptr)
        c
      end
      def self.category_tospeaker=(c)
        err_ptr = Pointer.new(:object)
        AVAudioSession.sharedInstance.setCategory(c, mode: AVAudioSessionModeDefault, options: AVAudioSessionCategoryOptionDefaultToSpeaker, error: err_ptr)
        AVAudioSession.sharedInstance.setActive(true, error: err_ptr)
      end
    end

    class Recorder
      def self.permitted?
        case AVAudioSession.sharedInstance.recordPermission
        when 1970168948 #undefined
          return nil
        when 1735552628 #permitted
          return true
        else
          return false
        end
      end
      def self.request_permission(fail = Proc.new { }, suc = Proc.new { }, ign = Proc.new { })
        UI.alert(:title => _("Do you wish to enable microphone access?"), :message => _("Elten requires microphone access in order to record audio data. Do you wish to grant it now?"), :default => _("Yes"), :cancel => _("Not now")) { |ind|
          if ind == :default
            AVAudioSession.sharedInstance.requestRecordPermission(->granted {
              if granted == false
                fail.call
              else
                suc.call
              end
            })
          else
            ign.call
          end
        }
      end
      QualityMin = AVAudioQualityMin.to_i
      QualityLow = AVAudioQualityLow.to_i
      QualityMedium = AVAudioQualityMedium.to_i
      QualityHigh = AVAudioQualityHigh.to_i
      QualityMax = AVAudioQualityMax.to_i
      attr_reader :file, :freq, :ch, :quality

      def initialize(file, quality = QualityHigh, ch = 2, freq = 44100)
        @file, @ch, @freq, @quality = file, ch, freq, quality
        @url = NSURL.fileURLWithPath(@file)
        kAudioFormatMPEG4AAC = 1633772320
        configs = { AVFormatIDKey => kAudioFormatMPEG4AAC, AVNumberOfChannelsKey => ch, AVEncoderAudioQualityKey => quality, AVSampleRateKey => freq }
        @err_ptr = Pointer.new(:object)
        @recorder = AVAudioRecorder.alloc.initWithURL(@url, settings: configs, error: @err_ptr)
      end

      def error?
        @err_ptr.code > 0
      end

      def record
        start
      end

      def start
        return false if !@recorder.prepareToRecord
        @recorder.record
      end

      def stop
        @recorder.stop
      end
    end

    class Player
      StateNone = 0
      StatePlaying = 1
      StatePaused = 2
      StateError = 3
      attr_reader :file

      def initialize
        @player = ORGMEngine.alloc.init
      end

      def play(file)
        if file.include?(":")
          @player.playUrl(NSURL.URLWithString(file))
          @file = file
        elsif FileTest.exists?(file)
          @player.playUrl(NSURL.fileURLWithPath(file))
          @file = file
        end
      end

      def state
        @player.currentState
      end

      def pause
        @player.pause
      end

      def resume
        @player.resume
      end

      def stop
@file=nil
        @player.stop
      end

      def position
        @player.amountPlayed
      end

      def duration
        @player.trackTime
      end

      def error?
        @player.currentError.description
      end
    end
  end
end

class Object
  include EltenAPI::Sound
end
