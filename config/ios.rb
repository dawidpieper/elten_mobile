# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

# Elten Mobile iOS Configuration

require 'rubygems'
require 'motion-cocoapods'
require 'motion-i18n'

Motion::Project::App.setup do |app|
    app.name = 'Elten'
app.version='0.06'
app.short_version = '0.04'

app.identifier='eu.elten-net.eltenmobile'
#app.libs<<'/usr/lib/libstdc++.6.0.9.dylib'

app.frameworks << "AVFoundation"

app.pods do
pod 'OrigamiEngine/Opus'
end

app.info_plist['UIRequiredDeviceCapabilities']=['arm64']
app.info_plist['NSMicrophoneUsageDescription']='Elten requires access to your microphone in order to record audio posts, messages and so on.'

app.release do
#app.codesign_certificate = 'iPhone Distribution: Dawid Pieper (YC6NP473J2)'
app.codesign_certificate = "iPhone developer: Dawid Pieper"
app.provisioning_profile = "eltenmobile_beta.mobileprovision"
app.entitlements['aps-environment'] = 'production'
end

app.development do
app.codesign_certificate = 'iPhone developer: Dawid Pieper'
app.provisioning_profile = "eltenmobile_beta.mobileprovision"

app.entitlements['aps-environment'] = 'development'
end

end

