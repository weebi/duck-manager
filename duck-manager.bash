#!/bin/bash

_token=""

_login() {
    while :
    do
        read -p "Enter duck.com username: " _username

        [[ -n "$_username" ]] && \
        echo "Attempting to log in..." && \
        curl -s "https://quack.duckduckgo.com/api/auth/loginlink?user=${_username}" -H 'Content-Type: application/json' -o /dev/null && \
        echo "Check your email for the verification code." && \
        break

        [[ -z "$_username" ]] && \
        echo "Username cannot be blank."
    done

    while :
    do
        read -p "Enter the verification code: " _verification_code

        _login_data=$(curl -s "https://quack.duckduckgo.com/api/auth/login?otp=${_verification_code//$' '/%20}&user=${_username}" -H 'Content-Type: application/json')

        [[ -n "$_login_data" ]] && \
        _token=$(echo "${_login_data}" | jq -r .token) && \
        tee ~/.config/duck-manager.conf <<< "$_token" > /dev/null && \
        break

        [[ -z "$_login_data" ]] && \
        echo "Code is either wrong or something else failed, try again."
    done
}


_alias() {
    echo "Logged in, creating new alias"

    _dashboard_data=$(curl -s -H "Authorization: Bearer ${_token}" -H 'Content-Type: application/json' https://quack.duckduckgo.com/api/email/dashboard)
    _access_token=$(echo "${_dashboard_data}" | jq -r .user.access_token)

    _address_data=$(curl -s https://quack.duckduckgo.com/api/email/addresses -H "Authorization: Bearer ${_access_token}" -X POST)
    [[ -n "$_address_data" && $(jq ."error" <<< "$_address_data") = "null" ]] && \
    _address=$(echo "${_address_data}" | jq -r .address) && \
    echo "Your new alias is ${_address}@duck.com!"

    [[ -z "$_address_data" || $(jq ."error" <<< "$_address_data") != "null" ]] && \
    echo "Something went wrong, try again." && \
    _login && \
    _alias
}

[[ ! -s ~/.config/duck-manager.conf ]] && \
_login

[[ -s ~/.config/duck-manager.conf ]] && \
_token=$(cat ~/.config/duck-manager.conf)

_alias
