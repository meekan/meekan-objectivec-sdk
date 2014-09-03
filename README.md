[Meekan](http://meekan.com) is a platform that helps people schedule meetings.

Our API can help developers integrate calendar event creation and modification, availability lookups, and time suggestions.

## How To Get Started

- Request an API key - email us at [info@meekan.com](mailto:info@meekan.com?subject=API%20Key), telling us a bit about yourself and what you will build.
- Check out the [playground](http://playground.meekan.com) for a look at our available APIs, and a comprehensive getting started guide.
- Install the SDK

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries.

#### Podfile

```ruby
platform :ios, '7.0'
pod 'MeekanSDK', '~> 1.0'
```
## Usage

Initialize a shared `MeekanSDK` instance using your API Key
```
MeekanSDK *sdk =[MeekanSDK sharedInstanceWithApiKey:@"YOUR_API_KEY_HERE"];
```

### Login

You must be logged in as a Meekan User to perform operations on the backend.

There are 2 options exposed for now to login - via Google OAuth2, or directly to an exchange account.

Once connected, you get an object describing your user and accounts. More than one account can be connected to the current user, but using the "connect" method again.

#### Google Login

```objective-c
MKNGoogleLoginViewController *viewController = [sdk connectWithGoogleWithCompletionHandler:^(MKNGoogleLoginViewController *vc, ConnectedUser *user, NSError *error) {
  if (user) {
    // Save current user and accounts
    NSLog(@"User primary Email: %@", user.primaryEmail);
    } else {
      //
    }
  }];
[self.navigationController pushViewController:viewController animated:YES];
```

#### Exchange Login

```objective-c
[self.sdk connectWithExchangeUser:accountParams[@"username"] withPassword:accountParams[@"password"] withEmail:accountParams[@"email"] withServerUrl:accountParams[@"url"] andDomain:accountParams[@"domain"] onSuccess:^(ConnectedUser *user) {
    // Save connected user account details.
  } onError:^(NSError *err) {
    // Handle bad authentication details, retry
  }];

```

### Suggested Times for a meeting

Availability lookup allows you to find suggested times for a meeting using Meekan's schedueling engine. You use it by providing time frames for the meeting, as well as account IDs of participants. The operations returns ranked time slots based on availability.

```objective-c
SlotSuggestionsRequest *request = [[SlotSuggestionsRequest alloc]init];
request.organizerAccountId = @"YOUR_ACCOUNT_ID";
request.duration = 45; // Minutes
NSDate *now = [NSDate dateWithTimeIntervalSince1970:trunc([[NSDate date] timeIntervalSince1970])];
NSDate *inTwoHours = [now dateByAddingTimeInterval:120 * 60];
NSDate *inThreeHours = [now dateByAddingTimeInterval:180 * 60];
NSDate *inFourHours = [now dateByAddingTimeInterval:240 * 60];
request.timeFrameRanges = @[ @[now, inTwoHours],
                             @[inThreeHours, inFourHours];
[self.sdk suggestedSlots:request onSuccess:^(NSArray *slotSuggestions) {
  for (SlotSuggestion *suggestion in slotSuggestions) {
    NSLog(@"Start: %@, Unavailable: %@", suggestion.start, suggestion.busyIds);
  }
  NSSet *times = [NSSet setWithArray:[slotSuggestions valueForKey:@"start"]];
  } onError:^(NSError *err) {
    NSLog(@"Oops: %@", err);
}];
```

### Meeting Creation

The `MeetingDetails` instance contains information about the meeting to create.

- A meeting with no options is considered a draft meeting.
- A meeting with a single options will be created on calendar account, and invitations will be sent to invitees from the calendar provider.
- A meeting with multiple options will create a poll for preferred times among the invitees. It will also book the optional times in your calendar account.

```objective-c
MeetingDetails *details = [[MeetingDetails alloc]init];
details.accountId = @"4785074604081152";
details.title = @"Test Multiple";
details.durationInMinutes = 10;
NSDate *start = [NSDate dateWithTimeIntervalSince1970:1409477400];
NSSet *options = [NSSet setWithObjects:
  [start dateByAddingTimeInterval:3600],
  [start dateByAddingTimeInterval:7200],
  [start dateByAddingTimeInterval:10800], nil];
details.options = options;
details.participants = [[MeetingParticipants alloc]init];
    
[self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
    NSLog(@"Created Meeting with ID: %@"details.meetingId);
  } onError:^(NSError *err) {
    // Handle error    
}];
```

### More
`MeekanSDK` class contains all wrapped methods for now. Take a look at the exposed operations.

## Communication

We'd love to hear your feedback. Send us issues or a pull request here, or contact us via email on [api@meekan.com](mailto:api@meekan.com).
