## 0.1.12

- Added bodyAsModelList to ModelRequest

## 0.1.11

- Changed AuthenticatedResponseBuilder to have a constant constructor
- Added hideMissingError field to AuthenticatedResponseBuilder to hide the 401 when authorization is missing with a 404

## 0.1.10

- Fixed Missing Import for BaseModelFieldExtension

## 0.1.9

- Changed event_db and event_db_tester to accept the new 0.2.0 version as well.

## 0.1.8

- Added logStackTrace to ResponseErrorBuilder which can be set to true to log the stackTrace as well as the thrown exception itself.

## 0.1.7

- Updated to accept mocktail ^0.3.0 as well as ^1.0.0

## 0.1.6

- Updated to accept dart_frog ^0.3.0 as well as ^1.0.0
- Added TestRequestContext to conveniently have an implementation of read and provide by Extension
- Fixed tests

## 0.1.5

- Added SecretsOrigin and FileSecretsOrigin to maintain and attain secrets

## 0.1.4

- Added Validation and ValidationCollectionException default handling to ResponseErrorBuilder

## 0.1.3

- Added optional logAllErrors for ResponseErrorBuilder to enable logging of all thrown errors

## 0.1.2

- Added optional logger for ResponseErrorBuilder to enable logging for unexpected errors

## 0.1.1

- Moved HeaderExtension to event_authentication

## 0.1.0

- Initial version.
