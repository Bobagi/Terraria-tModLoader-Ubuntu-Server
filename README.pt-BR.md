# Servidor Dedicado de Terraria + tModLoader no Ubuntu — Guia Completo

> **Guia passo a passo para instalar, configurar e rodar um servidor dedicado de Terraria com mods (tModLoader) no Ubuntu / Linux.** Dois métodos: **Docker** (recomendado) e instalação **nativa**. Cobre mods da Steam Workshop, firewall (porta TCP 7777), limite de RAM, o famoso crash do `libicu` na inicialização e os erros mais comuns. Funciona em qualquer provedor de VPS (Hostinger, DigitalOcean, Hetzner, Vultr, AWS, Linode, Oracle Cloud, etc.).

[![Stars](https://img.shields.io/github/stars/Bobagi/Terraria-tModLoader-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/stargazers)
[![Forks](https://img.shields.io/github/forks/Bobagi/Terraria-tModLoader-Ubuntu-Server?style=for-the-badge)](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
![Terraria](https://img.shields.io/badge/Terraria-1A1A2E?style=for-the-badge&logo=terraria&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

---

**[🇺🇸 English version](README.md)**

---

## Índice
1. [Por que este guia?](#por-que-este-guia)
2. [Pré-requisitos](#pré-requisitos)
3. [Método A — Docker (recomendado)](#método-a--docker-recomendado)
4. [Método B — Instalação nativa](#método-b--instalação-nativa-sem-docker)
5. [Instalando mods](#instalando-mods)
6. [Como os jogadores conectam](#como-os-jogadores-conectam)
7. [Gerenciamento do servidor](#gerenciamento-do-servidor)
8. [Badge de status do servidor (opcional)](#badge-de-status-do-servidor-opcional)
9. [Solução de problemas](#solução-de-problemas)
10. [Perguntas frequentes (FAQ)](#perguntas-frequentes-faq)
11. [Mods de qualidade de vida recomendados](#mods-de-qualidade-de-vida-recomendados)
12. [Créditos](#créditos)
13. [Licença](#licença)

---

## Por que este guia?

A maioria dos tutoriais de **servidor de Terraria no Linux** para no servidor vanilla ou ignora as partes que realmente quebram um servidor **com mods (tModLoader)** — o firewall, a RAM, os mods da Workshop e os crashes crípticos de inicialização. Este guia nasceu de um deploy real e funcionando, e cobre:

- ✅ **Método Docker** (recomendado, reproduzível) — o jeito que a doc oficial do tModLoader sugere
- ✅ **Método nativo** (sem Docker) — a instalação clássica com o script oficial de gerenciamento
- ✅ Baixar **mods da Steam Workshop** no servidor por ID (sem upload manual)
- ✅ **Firewall** (TCP **7777**) e a pegadinha do "cloud firewall" do provedor de VPS
- ✅ **Limite de RAM** pra um modpack pesado (Calamity, Thorium…) não derrubar a máquina inteira
- ✅ Corrigir o **crash em loop `Couldn't find a valid ICU package`** (falta o `libicu`)
- ✅ Corrigir o **container que sai na hora** (falta de TTY / loop de restart por EOF)
- ✅ Uma **lista de mods de qualidade de vida** testada, com os IDs da Workshop

Seja pra jogar **Calamity** com os amigos ou só um mundo pequeno levemente modado, aqui você fica online.

---

## Pré-requisitos

Antes de começar:

- Uma VPS ou máquina com **Ubuntu 22.04 / 24.04 LTS** (ou Debian 12) — 64 bits
- **RAM:** 2 GB dão conta de um mundo pequeno com poucos mods; **4 GB+** recomendado, **6–8 GB** para modpacks do tamanho do Calamity com vários jogadores
- Privilégios `sudo` e noções básicas de terminal
- Máquina **x86-64** — **ARM não é suportado** pelo servidor de Terraria/tModLoader
- Jogadores que tenham **Terraria** na Steam. Para servidor com mods, eles também precisam do **[tModLoader](https://store.steampowered.com/app/1281930/tModLoader/)** (grátis na Steam)
- O **servidor em si é grátis** e não precisa de conta Steam pra rodar

> 💡 **Qual método?** Use **Docker**, a menos que tenha um motivo pra não usar — ele isola o servidor, deixa mods e limite de RAM triviais, e é o que a documentação oficial do tModLoader recomenda. O método nativo está aqui para quem não pode/não quer usar Docker.

---

## Método A — Docker (recomendado)

Espelha um deploy real e funcionando. Usa a imagem da comunidade [`jacobsmile/tmodloader1.4`](https://github.com/JACOBSMILE/tmodloader1.4), que **baixa mods da Steam Workshop por ID numérico** — sem transferir arquivo na mão.

### 1. Instale o Docker

```bash
sudo apt-get update
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"   # depois faça logout/login pra valer
docker compose version            # confirme que o Compose V2 existe
```

### 2. Pegue os arquivos do servidor

```bash
git clone https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server.git
cd Terraria-tModLoader-Ubuntu-Server/docker
```

Você terá `docker-compose.yml`, um `Dockerfile` e `.env.example`.

### 3. Defina a senha do servidor

```bash
cp .env.example .env
nano .env            # defina TMOD_PASS=sua-senha-forte
chmod 600 .env       # mantém a senha privada
```

### 4. Configure o mundo e os mods

Abra o `docker-compose.yml` e ajuste o bloco `environment:`:

| Variável | Significado |
|---|---|
| `TMOD_WORLDNAME` | Nome do arquivo do mundo |
| `TMOD_WORLDSIZE` | `1` = Pequeno, `2` = Médio, `3` = Grande |
| `TMOD_DIFFICULTY` | `0` = Clássico, `1` = Expert, `2` = Master, `3` = Journey |
| `TMOD_MAXPLAYERS` | Máx. de jogadores (ex.: `8`) |
| `TMOD_AUTODOWNLOAD` | **IDs de mods da Workshop** para baixar (separados por vírgula) |
| `TMOD_ENABLEDMODS` | IDs para **ativar** (geralmente a mesma lista) |

O exemplo já vem com um pacote leve de qualidade de vida (veja [Mods recomendados](#mods-de-qualidade-de-vida-recomendados)). Para jogar **Calamity**, troque pelos IDs dele e aumente o `mem_limit`.

### 5. Entenda o `Dockerfile` (o fix do `libicu`)

O compose constrói uma **imagem derivada**: a imagem base + `libicu`. Isso **não é opcional** — sem ele o runtime .NET dentro do container entra em **loop de crash** com `Couldn't find a valid ICU package`. Veja [Solução de problemas](#solução-de-problemas). Você não precisa fazer nada; o `docker compose` constrói pra você.

### 6. Abra o firewall (TCP 7777)

O Terraria usa **porta TCP 7777**. Libere:

```bash
sudo ufw allow 22/tcp     # libere o SSH PRIMEIRO se usa UFW
sudo ufw allow 7777/tcp   # Terraria / tModLoader
sudo ufw enable
sudo ufw status
```

> ⚠️ Muitos provedores (Hostinger, Oracle Cloud, AWS, GCP) têm um **firewall na nuvem separado**. Você precisa abrir a **TCP 7777** lá também, senão os jogadores dão timeout mesmo com o UFW certo.

### 7. Suba o servidor

```bash
docker compose up -d          # a 1ª vez baixa .NET + mods e gera o mundo (alguns minutos)
docker compose logs -f        # acompanhe; espere "Server started"
```

Um primeiro boot saudável se parece com isto (trimado) — quando aparecer **`Server started`**, está no ar:

<details>
<summary>📟 Exemplo de saída do console do servidor</summary>

```text
[SYSTEM] Finished downloading mods.
Adding Content: Recipe Browser v0.12
Adding Content: Boss Checklist v2.2.4
Adding Content: Census - Town NPC Checklist v0.5.2.7
Adding Content: AlchemistNPC Lite v1.9.9
Adding Content: Ore Excavator (1.4.3/1.4.4 Veinminer) v0.8.9
[SYSTEM] Finished loading mods.
...
95.7% - Generating structures..Standard Minecart Tracks - 80.0%
96.0% - Generating structures..Lava Traps
Listening on port 7777
Type 'help' for a list of commands.
Server started
```
</details>

Pronto — seu servidor com mods está no ar em `ip-do-servidor:7777`. Pule para [Como os jogadores conectam](#como-os-jogadores-conectam).

---

## Método B — Instalação nativa (sem Docker)

Prefere sem Docker? Use o script **oficial** [tModLoader Dedicated Server Utils](https://docs.tmodloader.net/docs/stable/md__github_workspace_src_t_mod_loader__terraria_release_extras__dedicated_server_utils__r_e_a_d_m_e.html).

### 1. Crie um usuário dedicado

```bash
sudo adduser terraria
sudo su - terraria
```

### 2. Instale as dependências (incluindo `libicu`)

O servidor tModLoader roda em .NET, que precisa do **ICU** para globalização — exatamente o que falta no caso do Docker:

```bash
sudo apt-get update
sudo apt-get install -y libicu-dev tar gzip wget
```

### 3. Abra o firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 7777/tcp
sudo ufw enable
```

### 4. Baixe o servidor tModLoader

Pegue o script oficial e instale o servidor **pela release do GitHub** (anônimo — sem login Steam):

```bash
cd ~
mkdir -p tModLoaderServer && cd tModLoaderServer
# Baixe o manage-tModLoaderServer.sh da última release do tModLoader:
#   https://github.com/tModLoader/tModLoader/releases  (nos arquivos do servidor)
./manage-tModLoaderServer.sh install-tml --github
```

> Alternativa: `install-tml --username <seu_usuario_steam>` instala via SteamCMD. A rota `--github` não precisa de conta Steam e é a mais simples num servidor headless.

### 5. Configure o servidor

```bash
cp /caminho/para/native/serverconfig.txt.example ~/tModLoaderServer/serverconfig.txt
nano ~/tModLoaderServer/serverconfig.txt   # worldname, difficulty, password, maxplayers
```

### 6. Rode o servidor

**Simples (com `screen`):**

```bash
sudo apt-get install -y screen
screen -S terraria
cd ~/tModLoaderServer
./start-tModLoaderServer.sh -nosteam -config serverconfig.txt
# desanexe com Ctrl+A depois D; reanexe com: screen -r terraria
```

**Recomendado (auto-start com systemd):** use o unit pronto em [`native/tmodloader-server.service`](native/tmodloader-server.service):

```bash
sudo cp native/tmodloader-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now tmodloader-server
journalctl -u tmodloader-server -f
```

---

## Instalando mods

Os mods ficam na **Steam Workshop**. Cada mod tem um **ID numérico** — o número na URL da Workshop:
`https://steamcommunity.com/sharedfiles/filedetails/?id=`**`2619954303`**.

### Docker

Coloque os IDs em **ambos** `TMOD_AUTODOWNLOAD` (baixar) e `TMOD_ENABLEDMODS` (ativar) no `docker-compose.yml`, e:

```bash
docker compose up -d
```

A imagem baixa e ativa automaticamente. Sem conta Steam, sem upload manual.

### Nativo

Crie um **Mod Pack** no cliente do tModLoader (Workshop → montar um Mod Pack), o que gera `install.txt` + `enabled.json`, copie pra `~/.local/share/Terraria/tModLoader/Mods/` e rode:

```bash
./manage-tModLoaderServer.sh install-mods
./manage-tModLoaderServer.sh start
```

> **Todo jogador precisa ativar os mesmos mods.** O tModLoader pode oferecer baixar os mods do servidor ao entrar (se estiverem na Workshop), mas o ideal é todo mundo já assinar a mesma lista antes.

---

## Como os jogadores conectam

1. Abra o **tModLoader** (não o Terraria vanilla) com os **mesmos mods ativados** do servidor.
2. **Multiplayer → Join via IP**
3. Digite o **IP público** do servidor, a porta **`7777`** e a **senha**.

Descubra o IP público do servidor com:

```bash
curl ifconfig.me
```

---

## Gerenciamento do servidor

### Docker

```bash
docker compose logs -f                       # logs ao vivo
docker exec tmodloader inject "say olá"       # roda um comando no console
docker exec tmodloader inject "playing"       # lista quem está conectado
docker exec tmodloader inject "save"          # força salvar o mundo
docker compose down                           # desliga (salva ao sair)
docker compose up -d                          # liga
docker stats --no-stream tmodloader           # RAM / CPU
```

### Nativo

```bash
screen -r terraria        # abre o console (digite: help, playing, save, exit)
journalctl -u tmodloader-server -f   # se usar systemd
```

### Backups

Faça backup do mundo regularmente. **Docker:**

```bash
tar czf backup-$(date +%F).tar.gz docker/data/tModLoader/Worlds
```

**Nativo:**

```bash
tar czf backup-$(date +%F).tar.gz ~/.local/share/Terraria/tModLoader/Worlds
```

---

## Badge de status do servidor (opcional)

Quer um badge mostrando se o **seu** servidor está online, assim?
`![Server status](https://img.shields.io/badge/terraria%20server-online-brightgreen)`

Dá pra montar **só com GitHub Actions** — sem serviço de terceiros, e sem colocar o IP do seu servidor em nenhum lugar público além das configurações privadas do seu repositório. Um workflow pronto pra copiar está em [`examples/server-status.yml`](examples/server-status.yml).

**Setup (uns 2 minutos):**

1. Copie [`examples/server-status.yml`](examples/server-status.yml) para `.github/workflows/server-status.yml` no **seu** repositório.
2. Vá em **Settings → Secrets and variables → Actions → Variables** e adicione:
   - `TERRARIA_HOST` = o IP ou hostname do seu servidor *(obrigatório)*
   - `TERRARIA_PORT` = `7777` *(opcional)*
3. Adicione o badge no seu README (troque `OWNER/REPO`):
   ```markdown
   ![Server status](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/OWNER/REPO/badges/server-status.json)
   ```
4. Rode uma vez pela aba **Actions** pra publicar o primeiro status.

O workflow faz um TCP-ping no seu servidor a cada 15 minutos e escreve um JSON de [endpoint do Shields.io](https://shields.io/badges/endpoint-badge) numa branch dedicada `badges` (nunca suja o histórico da `main`). Guardar o host numa **Variable do repositório** mantém seu IP fora dos arquivos commitados.

> 🔒 **Sobre privacidade:** um badge de status publica o endereço do seu servidor onde quer que ele apareça. Se você pretende esconder o IP de origem atrás de um CDN/proxy depois, aponte o `TERRARIA_HOST` para um **hostname** que você controla, em vez do IP cru.

---

## Solução de problemas

### ❌ Container em loop de crash: `Couldn't find a valid ICU package`

A falha nº 1 do tModLoader no Linux. O runtime .NET força a cultura `en-US` na inicialização e aborta se o **ICU** não estiver instalado, então o container reinicia pra sempre (cada volta re-baixando os mods). Confirme no `tModLoader-Logs/Natives.log`:

```
Process terminated. Couldn't find a valid ICU package installed on the system.
```

**Fix (Docker):** instale o `libicu` numa imagem derivada — o `Dockerfile` deste repo já faz isso:

```dockerfile
FROM jacobsmile/tmodloader1.4:latest
RUN apt-get update && apt-get install -y --no-install-recommends libicu78 && rm -rf /var/lib/apt/lists/*
```

**Fix (nativo):** `sudo apt-get install -y libicu-dev`.

> ⚠️ **NÃO "resolva" com `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`.** Isso tira o erro do ICU, mas aí o tModLoader crasha com `en-US is an invalid culture identifier` — ele exige uma cultura de verdade. Instale o ICU; não desligue a globalização.
>
> Se o nome do pacote der erro, sua base usa outro Ubuntu: tente `libicu76`, `libicu74` ou `libicu72` (case com a release do Ubuntu da imagem base).

### ❌ Container sobe e sai na hora (loop de restart, exit code 0)

O console do servidor lê da stdin; sem TTY ele recebe EOF e sai limpo, e o Docker reinicia pra sempre. **Fix:** garanta no serviço do compose:

```yaml
    stdin_open: true
    tty: true
```

### ❌ "Connection failed" / jogadores não entram

- Confirme a porta aberta: `sudo ufw status` → procure **`7777/tcp`**
- Abra a **TCP 7777** no **firewall na nuvem do provedor** também (a causa nº 1)
- Confirme que o servidor está no ar: `docker compose logs --tail=20` deve mostrar `Server started` / `Listening on port 7777`
- Confira o IP público: `curl ifconfig.me`
- Garanta que os jogadores usam **os mesmos mods** e abrem o **tModLoader**, não o Terraria vanilla

### ❌ Servidor morto / estouro de memória (OOM)

Modpacks pesados (Calamity e cia.) podem usar 4–6 GB. Se o host é pequeno, limite o container pra ele não levar tudo junto — este repo usa `mem_limit: 4g`. Aumente se tiver RAM, ou use uma lista mais leve. Veja com `docker stats`.

### ❌ Mods baixaram mas não estão ativos

Garanta que cada ID esteja em **ambos** `TMOD_AUTODOWNLOAD` e `TMOD_ENABLEDMODS` (Docker), ou que o `enabled.json` liste eles (nativo). Reinicie após qualquer mudança.

### ❌ O mundo não gerou / dificuldade errada

Dificuldade e tamanho são fixados na criação do mundo. Para regerar, pare o servidor, apague os arquivos `.wld`/`.twld` da pasta `Worlds`, ajuste as configs e suba de novo.

---

## Perguntas frequentes (FAQ)

**P: Preciso ter o Terraria (ou instalar algo da Steam) pra rodar o servidor?**
R: Não. O servidor dedicado é grátis e roda sem conta Steam. Só os **jogadores** precisam ter o Terraria e, para servidor com mods, rodar o **tModLoader** (grátis na Steam) com os mesmos mods.

**P: Qual porta o servidor de Terraria usa?**
R: **TCP 7777** por padrão. Abra no firewall do SO *e* no firewall na nuvem do provedor. (É TCP — diferente de jogos que usam UDP.)

**P: Docker ou nativo — qual é melhor?**
R: **Docker.** É o que a doc oficial do tModLoader recomenda, isola o servidor e deixa mods e limite de RAM triviais. Use nativo só se não puder rodar Docker.

**P: Quanta RAM um servidor tModLoader precisa?**
R: Mundo pequeno com poucos mods fica em ~1 GB. Reserve **2–3 GB** para uma lista moderada e **4–6 GB** para modpacks do tamanho do Calamity com vários jogadores.

**P: Como adiciono o mod Calamity?**
R: Coloque o ID da Workshop do Calamity (e dos add-ons) em `TMOD_AUTODOWNLOAD`/`TMOD_ENABLEDMODS`, aumente o `mem_limit` e `docker compose up -d`. Todo jogador também precisa ativar o Calamity.

**P: Jogadores no Terraria vanilla conseguem entrar num servidor tModLoader?**
R: Não. Servidor com mods (tModLoader) exige clientes tModLoader. Para servidor sem mods, rode o servidor dedicado vanilla — mesma porta 7777.

**P: Dá pra rodar num Raspberry Pi / servidor ARM?**
R: Não. O servidor dedicado de Terraria/tModLoader é **só x86-64**.

**P: Como movo um mundo de single-player pro servidor?**
R: Copie o `.wld` (e o `.twld`) pra pasta `Worlds` do servidor e ajuste `TMOD_WORLDNAME` (Docker) ou `worldname` (nativo) pro nome do arquivo.

**P: O servidor sobe mas ninguém entra — o que checar primeiro?**
R: Nesta ordem: (1) firewall na nuvem do provedor, (2) `sudo ufw status` com `7777/tcp`, (3) IP público correto, (4) jogadores no tModLoader com os mesmos mods, (5) logs do servidor por `Server started`.

**P: Qual provedor de VPS usar?**
R: **Hetzner** e **Vultr** têm ótimo custo/benefício; **Hostinger** é econômico; **Oracle Cloud** tem tier grátis (shape x86). Escolha o datacenter mais perto dos jogadores pra menor ping.

**P: Como faço o servidor reiniciar sozinho após reboot ou crash?**
R: Docker: `restart: unless-stopped` (já vem setado). Nativo: o unit **systemd** com `Restart=on-failure` e `systemctl enable`.

---

## Mods de qualidade de vida recomendados

Um pacote leve e testado que melhora o multiplayer sem mexer no balanceamento. São os IDs do `docker-compose.yml` de exemplo:

| Mod | ID da Workshop | O que faz |
|---|---|---|
| Recipe Browser | `2619954303` | Busca/visualiza todas as receitas |
| Magic Storage | `2563309347` | Armazenamento central unificado |
| Boss Checklist | `2669644269` | Ordem dos bosses + drops |
| Census – Town NPC Checklist | `2687866031` | O que cada NPC precisa pra aparecer |
| AlchemistNPC Lite | `2599842771` | NPC que vende poções e ingredientes |
| Ore Excavator | `2565639705` | Vein-mining (mina o filão inteiro de uma vez) |

Quer mods de conteúdo? Adicione **Calamity**, **Thorium**, **Spirit** etc. pelos IDs da Workshop — só lembre de aumentar o `mem_limit` e todo jogador ativar eles.

---

## Créditos

- [tModLoader](https://github.com/tModLoader/tModLoader) e a [documentação do servidor dedicado](https://docs.tmodloader.net/docs/stable/md__github_workspace_src_t_mod_loader__terraria_release_extras__dedicated_server_utils__r_e_a_d_m_e.html)
- [JACOBSMILE/tmodloader1.4](https://github.com/JACOBSMILE/tmodloader1.4) — a imagem Docker usada aqui
- [Terraria Wiki — Server](https://terraria.wiki.gg/wiki/Server) e a [Re-Logic](https://www.terraria.org/) pelo jogo
- Todo mundo que abre issues e contribui com melhorias ❤️

---

## 💖 Apoie este projeto

Se este guia te economizou tempo, deixa uma ⭐ no repo — ajuda outras pessoas a encontrarem!

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/donate?hosted_button_id=23PAVC8AMJGYW)

---

## Contato & Contribuição

Achou um erro no guia ou tem uma dica?
👉 **[Abra uma issue](https://github.com/Bobagi/Terraria-tModLoader-Ubuntu-Server/issues/new/choose)** — todo feedback é bem-vindo.

Pull requests também são bem-vindos. Veja o [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Licença

Projeto open-source sob a [Licença MIT](LICENSE).
