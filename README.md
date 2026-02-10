# MenuAcessosProUI


Aplicativo macOS (SwiftUI) para organizar e abrir acessos de **Clientes** e seus endpoints de **SSH**, **RDP** e **URLs HTTPS** (ex.: firewall, VMware), com armazenamento local em CSV e interface em tema escuro (tons de azul/preto).

---

## Recursos

- ✅ Cadastro de **Clientes**
- ✅ Cadastro de acessos:
  - **SSH** (host, usuário e **porta digitável**)
  - **RDP** (host, usuário/domínio e **porta digitável**; gera `.rdp` com `server port:i:`)
  - **HTTPS (URL)** (host + porta, padrão 443, aceita portas customizadas)
- ✅ Ações:
  - **Abrir** (1 clique)
  - **Editar**
  - **Apagar**
- ✅ Persistência local em `~/.menu-acessos/`
- ✅ (Opcional) Gráfico/estatísticas conforme `LogParser.swift`

---

## Requisitos

- macOS (Apple Silicon / Intel)
- Xcode 15+ (recomendado)
- Swift 5.9+ (recomendado)

---

## Como executar (desenvolvimento)

1. Clone o repositório
2. Abra o projeto no Xcode (`.xcodeproj` ou `.xcworkspace`)
3. Selecione o target macOS
4. Execute com `Run` (⌘R)

---

## Estrutura de dados (CSV)

O app mantém os arquivos CSV em:


Arquivos:

- `clients.csv`
- `ssh.csv`
- `rdp.csv`
- `urls.csv`
- `rdpfiles/` (diretório onde os `.rdp` podem ser gerados)

### clients.csv

Header:
