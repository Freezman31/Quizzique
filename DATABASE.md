# Database scheme

## Collections

### Quiz
#### Attributes
- **name**: String
- **questions**: String[]
- **owner**: relationship with User
- **durationBeforeAnswer**: int
#### Permissions
- Any: can read
- Users: can create, update their own quizzes


### Games
#### Attributes
- **code**: int
- **quiz**: relationship with Quiz
- **players**: String[]
- **owner**: relationship with User
- **ended**: boolean
- **currentQuestion**: String
#### Permissions
- Any: can read, update
- Users: can create, read, update

### Answers
#### Attributes
- **games**: relationship with Game
- **answer**: int
- **correct**: boolean
- **playerID**: String
- **score**: int
- **questionID**: String
#### Permissions
- Any: can create

### Users
#### Attributes
- **userID**: string (unique identifier)
- **username**: string
- **quizzes**: relationship with Quiz[]
- **games**: relationship with Game[]
#### Permissions
- Guests: can create
- Users: can read, update their own data

### Scores
#### Attributes
- **game**: relationship with Game
- **playerID**: String
- **playerName**: String
- **score**: int
#### Permissions
- Any: can read
