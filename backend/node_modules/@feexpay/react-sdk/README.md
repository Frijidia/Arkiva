Installation

With npm :
```bash
npm install @feexpay/react-sdk
```

With yarn :
```bash
yarn add @feexpay/react-sdk
```

Initialisation:

To import the library, we can make :

```bash
import Feexpay from ‘’@feexpay/react-sdk’’
```


To init and add the payment button, you add this code in script balise.

```bash
<Feexpay
    token = {’/*API KEY*/’}
    id = {’/*Shop's id */ ‘}
    amount = {/*Montant du paiement à effectuer */}
    callback={()=>alert(‘’Pay’’)}
    description={'description'}
    callback_url={"https://www.feexpay.me"}
    callback_info={"callback_info"}
    buttonText="Payer"
    buttonClass={"mt-3"}
    defaultValueField={{'country_iban': "BJ"}}
/>
```

token (string): your token API key. 

id (string): your shop's id. 

callback (function): Function called back after payment has been made. This is optional.

callback_url (string): redirect url after payment. This is optional.

amount (int): Amount of payment to be made in XOF.

fieldsToHide (array): By example, you can put fieldsToHide={['email', 'full_name']}

buttonText: The text to be displayed on the payment button before the amount. By example buttonText="Payer".

buttonStyles: Sets of css properties to customize the start button. By example: buttonStyles={{ backgroundColor: "red", color: "black", borderRadius: "25px", width: '25%' }}.

buttonClass (string): Sets of css class name to customize the start button. By example: buttonClass={'mt-4 text-center'}.

defaultValueField: object to auto-complete certain fields. By example: defaultValueField={{'country_iban': "BJ"}}

You can get the shop's id and token API in your account FeexPay in Developer Menu. You won't need to define both callback and callback_url.

