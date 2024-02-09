#!/bin/bash

# Lia Batlle
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c "
NUMBER_ATTEMPTS=0
SECRET_NUMBER=$((1 + $RANDOM % 1000))

#Realiza todas las consultas en la base de datos construyendo su resultado, la variable QUERY_RESULT
SQL_QUERY(){
  QUERY_RESULT="$($PSQL "$1")"
}

#Inserta un usuario en la base de datos si aún no existe
SQL_INSERT_USER(){
  SQL_QUERY "INSERT INTO users (username,games_played,best_game) VALUES('$USER_NAME', 0, 0)"
  if [[ "$QUERY_RESULT" != "INSERT 0 1" ]]
  then
    echo "User not inserted into database"
    exit 1
  fi
}

#La información del usuario se toma asignándola a las variables USER_ID NOMBRE GAMES_PLAYED BEST_GAME
SQL_GET_USER(){
  SQL_QUERY "SELECT * FROM users WHERE username='$USER_NAME'"
  IFS="|" read USER_ID NAME GAMES_PLAYED BEST_GAME <<< "$QUERY_RESULT"
}

#Comprueba si existe un usuario, en caso afirmativo, muestra el mensaje no más a MAIN, si no, inserta el usuario en la base de datos
SQL_CHECK_EXISTENCE(){
  SQL_GET_USER
  if [[ -z $USER_ID ]]
  then
    echo "Welcome, $USER_NAME! It looks like this is your first time here."
    SQL_INSERT_USER
    SQL_GET_USER
  else    
    echo "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
}

#Sempre termina una partida, el número de veces que juegas games_played aumenta a 1 y mayúsculas y minúsculas. 
#o número de intentos para terminar el juego es menor que el más bajo jugado anteriormente,
#ese valor se actualiza en best_game
SQL_UPDATE_USER(){
  if [[ $BEST_GAME -gt $NUMBER_ATTEMPTS || $BEST_GAME -eq 0 ]]
  then
    SQL_QUERY "UPDATE users SET games_played=$(($GAMES_PLAYED+1)) , best_game=$NUMBER_ATTEMPTS WHERE user_id=$USER_ID"
  else
    SQL_QUERY "UPDATE users SET games_played=$(($GAMES_PLAYED+1)) WHERE user_id=$USER_ID"
  fi
}

#Lógica del juego
RANDOM_GAME(){
  NUMBER_ATTEMPTS=$((NUMBER_ATTEMPTS+1))
  read NUMBER_GUESS

  if [[ "$NUMBER_GUESS" =~ ^[0-9][0-9]?[0-9]?[0-9]?$ ]]
  then
    if [[ "$SECRET_NUMBER" -eq "$NUMBER_GUESS" ]]
    then
      echo "You guessed it in $NUMBER_ATTEMPTS tries. The secret number was $SECRET_NUMBER. Nice job!"
      SQL_UPDATE_USER
      exit 0
    elif [[ "$SECRET_NUMBER" -lt "$NUMBER_GUESS" ]]
    then
      echo "It's lower than that, guess again:"
      RANDOM_GAME
    else
      echo "It's higher than that, guess again:"
      RANDOM_GAME
    fi
  else
    echo "That is not an integer, guess again:"
    NUMBER_ATTEMPTS=$((NUMBER_ATTEMPTS-1))
    RANDOM_GAME
  fi
}

MAIN(){
  echo "Enter your username:"
  read USER_NAME
  SQL_CHECK_EXISTENCE
  echo "Guess the secret number between 1 and 1000:"
  RANDOM_GAME
}

MAIN
