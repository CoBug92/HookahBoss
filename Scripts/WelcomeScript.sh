# install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install ruby
brew install rbenv
rbenv install 2.5.0
rbenv global 2.5.0

# install gems
gem install fastlane xcode-install cocoapods

# install xcode
xcversion update
xcversion install 12.4

# install utilities
brew install swiftlint
brew install swiftgen

# congratulate for pacience!
echo "Thank you for your patience! All set up! Let's code!"
