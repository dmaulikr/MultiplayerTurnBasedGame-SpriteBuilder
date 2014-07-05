//
//  GameDataUtils.c
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 19/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameDataUtils.h"
#import "Constants.h"
#import "UserInfo.h"
#import <mgwuSDK/MGWU.h>

NSString* getOpponentName(NSDictionary *gameData) {
  NSArray *players = gameData[@"players"];
  NSString *opponentName;
  
  if (players) {
    
    if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
      opponentName = [players objectAtIndex:1];
    else
      opponentName = [players objectAtIndex:0];
    
    return opponentName;
    
  } else {
    return gameData[@"opponent"];
  }
}

NSString* friendNameForUsername(NSString *username) {
  for (NSMutableDictionary *friend in [UserInfo sharedUserInfo].friends)
  {
    //Add friendName to game if you're friends
    if ([[friend objectForKey:@"username"] isEqualToString:username])
    {
      return [friend objectForKey:@"name"];
    }
  }
  
  return @"Random Player";
}

NSNumber* doesPlayerHaveMatchWithFriend(NSString *username) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    for (NSString *playerID in  game[@"players"]) {
      if ([playerID isEqualToString:username]) {
        return game[@"gameid"];
      }
    }
  }
  
  return nil;
}

NSDictionary* getMatchById(NSNumber *matchID) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    if ([game[@"gameid"] isEqualToNumber:matchID]) {
      return game;
    }
  }
  
  return nil;
}

void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback) {
  int nextMoveNumber = [game[@"movecount"] intValue] + 1;
  int gameID =  [game[@"gameid"] intValue];
  
  NSString *oponnentUserName = getOpponentName(game);
  NSString *playerUserName = playerName;
  NSString *newGameState = game[@"gamestate"];
  
#ifdef DEBUG
  if ([playerName isEqualToString:BOT_USERNAME]) {
    oponnentUserName = playerUserName;
  }
#endif
  
  if (newGameState == nil) {
    newGameState = GAME_STATE_STARTED;
  } else if (nextMoveNumber > 1) {
    newGameState = GAME_STATE_IN_PROGRESS;
  }
  
  // After 6 rounds, mark game as completed
  if (nextMoveNumber == 6) {
    newGameState = GAME_STATE_COMPLETED;
  }
  
  // add a move to the game data
  NSMutableDictionary *gameData = game[@"gamedata"];
  
  if (!gameData) {
    gameData = [NSMutableDictionary dictionary];
  }
  
  // calculate current round (move 0 and 1 are part of round 1, move 2 and 3 are part of round 2, etc.)
  NSInteger currentRound = currentRoundInGame(game);
  NSString *currentRoundString = [NSString stringWithFormat:@"%i",currentRound];
  
  NSMutableDictionary *currentRoundGameData = game[@"gamedata"][currentRoundString];
  
  if (!currentRoundGameData) {
    currentRoundGameData = [NSMutableDictionary dictionary];
    gameData[currentRoundString] = currentRoundGameData;
  }
  
  currentRoundGameData[playerUserName] = move;
  
  [MGWU move:@{@"selectedElement":move} withMoveNumber:nextMoveNumber forGame:gameID withGameState:newGameState withGameData:gameData againstPlayer:oponnentUserName withPushNotificationMessage:@"Round completed" withCallback:callback onTarget:target];
}

BOOL isCurrentRoundCompleted(NSDictionary *game) {
  NSInteger currentRound = currentRoundInGame(game) - 1;
  NSString *currentRoundString = [NSString stringWithFormat:@"%d", currentRound];
  
  // the current round is completed if we have MOVES_PER_ROUND moves for this round
  return [[game[@"gamedata"][currentRoundString] allKeys] count] == MOVES_PER_ROUND;
}

NSInteger currentRoundInGame(NSDictionary *game) {
  NSInteger currentRound = [game[@"movecount"] intValue] / 2;
  currentRound += 1;
    
  return currentRound;
}


NSInteger calculateWinner(NSString *movePlayer1, NSString *movePlayer2) {
  if ([movePlayer1 isEqualToString:movePlayer2]) {
    return 0;
  }

  NSArray *choiceArray = @[movePlayer1, movePlayer2];
  
  NSArray *sortedArray = [choiceArray sortedArrayUsingComparator:^NSComparisonResult(NSString *choice1, NSString *choice2) {
    NSComparisonResult comparisonResult = NSOrderedSame;
    
    if ([choice1 isEqualToString:CHOICE_SCISSORS]) {
      if ([choice2 isEqualToString:CHOICE_ROCK]) {
        // scissors loses against rock
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_PAPER]) {
        // scissors wins against paper
        comparisonResult = NSOrderedAscending;
      }
    }
    
    if ([choice1 isEqualToString:CHOICE_ROCK]) {
      if ([choice2 isEqualToString:CHOICE_PAPER]) {
        // rock loses against paper
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_SCISSORS]) {
        // rock wins against scissors
        comparisonResult = NSOrderedAscending;
      }
    }
    
    if ([choice1 isEqualToString:CHOICE_PAPER]) {
      if ([choice2 isEqualToString:CHOICE_SCISSORS]) {
        // paper loses against scissors
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_ROCK]) {
        // paper wins against rock
        comparisonResult = NSOrderedAscending;
      }
    }
    
    return comparisonResult;
  }];
  
  if ([sortedArray indexOfObject:movePlayer1] < [sortedArray indexOfObject:movePlayer2]) {
    // player 1 wins
    return -1;
  } else {
    // player 2 wins
    return 1;
  }
}


