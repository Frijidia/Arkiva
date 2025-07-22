import React from 'react';
import Feexpay from '@feexpay/react-sdk';

function App() {
  const customId = `ARKIVA_${Date.now()}`;
  return (
    <div style={{ padding: 40 }}>
      <h2>Test FeexPay React</h2>
      <Feexpay
        id="TON_SHOP_ID"
        amount={1}
        token="TA_CLE_API"
        callback={(response) => {
          console.log('Callback FeexPay:', response);
        }}
        callback_url="http://localhost:3000/api/payments/webhook"
        callback_info={{ custom_id: customId, autre_info: "test" }}
        mode="SANDBOX"
        description="Test React FeexPay"
        case="MOBILE"
        currency="XOF"
      />
    </div>
  );
}

export default App;