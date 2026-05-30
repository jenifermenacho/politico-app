const axios = require('axios');

async function test() {
  // 1. Test despesas
  try {
    const res = await axios.get('https://dadosabertos.camara.leg.br/api/v2/deputados/220593/despesas?ano=2023');
    console.log('Despesas 220593:', res.data.dados.slice(0, 2));
  } catch (e) { console.error('Erro despesas', e.message); }
}
test();
