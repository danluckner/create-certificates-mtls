#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo "Please run this script as root or using sudo!"; exit; fi;
echo "Running script as root or sudo!"

declare -g serverfilename
declare -g clientfilename
declare -g expirationca
declare -g countryname
declare -g state
declare -g city
declare -g organization
declare -g orgunit
declare -g commonname
declare -g email
declare -g password
declare -g expirationclient
declare -g serial

sudo apt update
sudo apt upgrade -y
sudo apt install gnutls-bin -y

#CA certificate
read -p  "Type the CA file name you want (don't type the extension) [ca]: " serverfilename

serverfilename=${serverfilename:-ca}

if [[ ! -f $serverfilename.key ]]; then
        #Expiration
        read -p "How many days for the CA expiration [3650]: " expirationca
        expirationca=${expirationca:-3650}

        #CountryName
        while true; do
                read -p "Country Name (2 letter code) [AU]: " countryname
                if [[ ! ${#countryname} -eq 2 ]]; then
                        echo "Sorry, the country needs to have 2 character code. Please, try again...";
                else
                        break;
                fi;
        done
        countryname=${countryname:-AU}

        #State or Province
        read -p "State or Province Name (full name) [Some-State] :" state
        state=${state:-Some-State}

        #City
        read -p "Locality Name (eg, city) []: " city
        city=${city:-}

        #Organization Name
        read -p "Organization  Name (eg, company) [Self-HostedACME]: " organization
        organization=${organization:-Self-HosteadACME}

        #Organization Unit
        read -p "Organizational Unit Name (eg, section) []: " orgunit
        orgunit=${orgunit:-}

        #Common Name
        read -p "Common Name (eg, server FQDN or YOUR name) []: " commonname
        commonname=${commonname:-}

        #Email addres
        read -p "Email addres []: " email
        email=${email:-}

        openssl ecparam -genkey -name secp256r1 | openssl ec -out $serverfilename.key

        openssl req -new -x509 -days $expirationca -key $serverfilename.key -out $serverfilename.pem  -subj "/C=$countryname/ST=$state/L=$city/O=$organization/OU=$orgunit/CN=$commonname/emailAddress=$email"
else
        #Verify if file exists and reads the metadata from the existing CA certificate to be reused in the client certificate
        echo $serverfilename.key "already exists. Reading certificates properties..."

        subject=$(openssl x509 -subject -noout -in $serverfilename.pem)
        prefix="subject="
        subject=${subject#"$prefix"}

        IFS=", =" read -a array <<< $subject

        for index in "${!array[@]}"
        do
                [[ "${array[index]}" = "C" ]] && countryname="${array[index + 1]}" && echo "Country name: " $countryname
                [[ "${array[index]}" = "ST" ]] && state="${array[index + 1]}" && echo "State: " $state
                [[ "${array[index]}" = "L" ]] && city="${array[index + 1]}" && echo "City: " $city
                [[ "${array[index]}" = "O" ]] && organizaton="${array[index + 1]}" && echo "Organization: " $organization
                [[ "${array[index]}" = "OU" ]] && orgunit="${array[index + 1]}" && echo "Organizational Unit: " $orgunit
                [[ "${array[index]}" = "CN" ]] && commonname="${array[index + 1]}" && echo "Common name: " $commonname
                [[ "${array[index]}" = "emailAddress" ]] && email="${array[index + 1]}" && echo "Email: " $email
        done
fi

#Client Certificate
read -p "Type the client certificate filename [client]: " clientfilename

clientfilename=${clientfilename:-client}

if [[ ! -f $clientfilename.key ]]; then
        #Password
        while true; do
                read -s -p "Create password for the client certificate []: " password
                echo
                read -s -p "Confirm password: " password2
                echo
                if [[ ! $password == $password2 ]]; then
                        echo "Password does not match, please try again..."
                else
                        echo "Password succesfull."
                        password=${password:-}
                        break;
                fi;
        done

        #ClientExpiration
        read -p "How many days for expiration of Client Certificates [365]: " expirationclient
        expirationclient=${expirationclient:-365}

        #Serial
        read -p "Was is the number of certificate [01]: " serial
        serial=${serial:-01}

        openssl ecparam -genkey -name prime256v1 | openssl ec -out $clientfilename.key

        openssl req -new -key $clientfilename.key -out $clientfilename.csr -subj "/C=$countryname/ST=$state/L=$city/O=$organization/OU=$orgunit/CN=$commonname/emailAddress=$email/challengePassword=$password"

        openssl x509 -req -days $expirationclient -in $clientfilename.csr -CA $serverfilename.pem -CAkey $serverfilename.key -set_serial $serial -out $clientfilename.crt

        certtool --load-privkey $clientfilename.key --load-certificate $clientfilename.crt --load-ca-certificate $serverfilename.pem --to-p12 --outder --outfile $clientfilename.p12 --p12-name $clientfilename --hash SHA1 --pkcs-cipher 3des-pkcs12 --password $password
else
        echo $clientfilename.key "already exists. Skipping the Client Certificate file creation."
fi
