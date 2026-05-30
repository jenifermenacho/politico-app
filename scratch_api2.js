const axios = require('axios');

async function test() {
  try {
    const res = await axios.get('https://dadosabertos.camara.leg.br/api/v2/votacoes?ano=2023&ordem=DESC&ordenarPor=dataHoraRegistro');
    console.log('Votacoes 2023:', res.data.dados.slice(0, 3));
  } catch (e) { console.error('Erro votacoes', e.message); }
}
test();
