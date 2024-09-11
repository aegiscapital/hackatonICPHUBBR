
## Repositório Público de Projeto para o Hackaton ICP HUB BR
#### Atenção: Esse repositório foi criado para a participação no Hackaton do HUB ICP BR e pode não conter todas as informações de futuras implementações do projeto.

# ICP Runes Control Panel

## Resumo

Esse projeto propõe-se a construir uma aplicação real de uso imediato para recompensar os membros da comunidade ICP HUB Brasil, auxiliar na propagação do conhecimento e visibilidade do HUB e incentivar outros projetos como comunidades e DAOs com esse mesmo objetivo.

## O Problema

A maioria das ferramentas hoje existentes para recompensar comunidades por engajamento e participação em eventos são off-chain, baseadas em sistemas de pontuação providos pelos próprios projetos de terceiros e limitadas às interações e redes sociais aceitas por eles.

## A Solução

Nossa solução permite a utilização de ativos onchain para recompensar a comunidade da ICP HUB BR em eventos, torneios e sorteios promovidos pelo HUB, de maneira flexível, permitindo uma integração tecnológica e de cunho educacional, tanto em relação a desenvolvimento na rede do Bitcoin quanto na rede ICP. 
Nosso projeto se utiliza de um padrão de "tokens" fungíveis extremamente inovador e revolucionário na rede do Bitcoin, as Runas, que foram lançadas em 20/04/2024 (Halving) graças a implementação do protocolo Ordinals, que traz a possibilidade de registrar uma quantidade muito maior de dados nos Satoshis (menor fração de 1 Bitcoin), como textos, fotos, vídeos e tokens. 
A partir da inscrição dessas runas, utilizamos a infraestrutura da Omnity Network para fazer uma ponte e representar esses ativos na rede da ICP, onde podem ser manipulados e enviados para vários usuários simultaneamente pelo canister do nosso projeto, de forma muito mais barata e escalável graças à estrutura da rede ICP.

## Nossa Visão

Nossa principal visão é unir a segurança e confiabilidade da rede do Bitcoin com a escalabilidade e programabilidade da rede ICP. Com isso, permitimos ao HUB ICP BR uma forma única, exclusiva e valiosa de recompensar os membros de sua comunidade. Nossa implementação permite o envio em massa dessas recompensas onchain para os membros da comunidade, além de permitir a programabilidade de outras ferramentas como bots de Discord e contratos automatizados para distribuição desses ativos.

## Como Fazemos 

- Passo 1: Inscrição dos ativos do protocolo Runes na rede L1 do Bitcoin, representando a ICP HUB BR na maior e mais segura blockchain existente.

- Passo 2: Registro das Runas na rede da ICP utilizando a ferramena de bridge da infraestrutura Omnity Network - https://bridge.omnity.network/runes 
(verificável via cannister criado pela própria Omnity Network em um processo de travamento de ativos na camada 1 do Bitcoin e emissão na rede ICP com o padrão IRCR-1)

- Passo 3: Registro do nosso próprio cannister para manipulação e distribuição das Runas/Tokens na rede ICP.

A principal ferramenta para criar, implementar e gerenciar os dapps para a plataforma da IC é a dfx (DFINITY command-line execution environment), que está contida na IC SDK (software development kit). 

Essa ferramenta não tem suporte nativo no Windows, portanto todo o desenvolvimento desse projeto foi centrado em uma configuração a partir de um ambiente WSL (Windows Subsystem for Linux).

Esse Canister possibilita uma distribuição automatizada das Runas armazenadas, bem como um controle de acesso para quem pode fazer essa distribuição.

#### Para o exemplo, vamos considerar que 5 pessoas ganharam uma competição de arte para a ICP Hub BR e estão elegíveis para receber uma premiação em Runas:

A – Aline – 16 Runas – xfznx-sgxv2-ty5tf-niw3v-6u34s-suz5w-xza2d-kwpwo-qq7fc-ug4oc-oqe

B – Bob – 8 Runas – 6fp7j-oxpeg-gwgjl-zvjsj-kmne4-wq6cw-wnh5h-tbfii-q2nvs-gwpvm-2ae

C – Carlos – 4 Runas – z3fut-ezcmm-f3qfz-4hxqz-7fmp7-bu74a-js3td-g5wr5-2ncqj-u5mwq-vqe

D – Denise – 2 Runas – pykrr-ecxve-bksoh-oipzw-hdpoj-djhdp-brkgd-h7h54-oincy-lu4wn-zqe

E – Edward – 1 Runa – mgc4g-k3pmg-wtkha-omup5-y7eom-ip4b5-lvjdx-qu5wr-nl6wm-vbhls-kae

#### Testando Localmente:

#### Primeiramente vamos fazer o deploy das Runas como um ICRC-1 localmente:

#### Para isso, primeiro definimos um “Minter” e uma conta padrão “Default” – para onde as Runas serão mintadas:

dfx identity new minter
dfx identity use minter
export MINTER=$(dfx --identity anonymous identity get-principal)
dfx identity new default
dfx identity use default
export DEFAULT=$(dfx identity get-principal)

#### E então podemos dar o deploy no Canister. Nessa configuração, serão mintadas 100 Runas para o
#### Principal “Default” e a taxa de transferência será inicializada em 0,0001 tokens.

dfx deploy icrc1_ledger_canister --argument "(variant { Init =
record {
 token_symbol = \"ICRC1\";
 token_name = \"L-ICRC1\";
 minting_account = record { owner = principal \"${MINTER}\" };
 transfer_fee = 10_000;
 metadata = vec {};
 initial_balances = vec { record { record { owner = principal \"${DEFAULT}\"; };
10_000_000_000; }; };
 archive_options = record {
 num_blocks_to_archive = 1000;
 trigger_threshold = 2000;
 controller_id = principal \"${MINTER}\";
 };
 }
})"

#### Com as Runas mintadas, vamos fazer o deploy do nosso Canister:

dfx deploy token_transfer_backend

#### E vamos chamar a função “transferPrivilege” passando de argumento o Principal que queremos utilizar como “Owner”, que fará a distribuição das Runas. Nesse caso será o próprio Principal que estamos usando (“Default”):

dfx canister call token_transfer_backend transferPrivilege "(principal \"$(dfx identity getprincipal)\")"

#### E finalmente podemos finalizar o nosso Setup Local transferindo Runas para o Canister. 
#### Nesse exemplo, vamos enviar 10 Runas:

dfx canister call icrc1_ledger_canister icrc1_transfer "(record {
 to = record {
 owner = principal \"$(dfx canister id token_transfer_backend)\";
 };
 amount = 1_000_000_000;
})"

#### Com o Setup finalizado, podemos fazer o uso do Canister utilizando nosso Principal “Default”.
#### Vamos fazer a distribuição das Runas da Denise e do Edward.
#### Como proteção para eventuais erros, o Canister requer que a lista de Accounts e a lista de Amounts possua o mesmo tamanho.

dfx canister call token_transfer_backend bulkTransfer "(record {
 amounts = vec {
 200_000_000;
 100_000_000;
 };
 toAccounts = vec {
 record { owner = principal \"pykrr-ecxve-bksoh-oipzw-hdpoj-djhdp-brkgd-h7h54-oincy-lu4wnzqe\" };
 record { owner = principal \"mgc4g-k3pmg-wtkha-omup5-y7eom-ip4b5-lvjdx-qu5wr-nl6wmvbhls-kae\" };
 };
})"

## Future Plans

**Distributing the Value of Co-created Collections to the Community**

- Resources: https://internetcomputer.org/docs/current/developer-docs/integrations/ethereum/evm-rpc

**Implementing Deeper DAO Structure Using SNS**

- Resources: https://internetcomputer.org/docs/current/tokenomics/

## Roadmap Details and History (Docs)

- Visit: https://aegis-protocol.gitbook.io/en/history/roadmap

## Project Media

- **Running Local Cannister**

![image](https://github.com/user-attachments/assets/65cfff03-8eea-46bf-92f4-a553d8be793a)

# **Website Demo Presentation**

## Link: [Website Demo](https://drive.google.com/file/d/1wQHYSEBa-bBeWwsc6JkYz_Ah56QBTijB/view?usp=sharing)

  
