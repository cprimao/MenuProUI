# MenuAcessosProUI (Menu Acessos Pro)

Aplicativo **macOS** (SwiftUI) para centralizar, organizar e abrir acessos de infraestrutura por **cliente**, suportando:

- **SSH** (host, usuário e **porta digitável**)
- **RDP** (host, usuário/domínio e **porta digitável**, com geração de `.rdp`)
- **HTTPS (URL)** para consoles web (Firewall, VMware, etc.), com **porta padrão 443** e suporte a portas customizadas

Os dados são persistidos localmente em arquivos **CSV** em `~/.menu-acessos/`.

---

## ✅ Principais recursos

### Clientes
- Cadastrar cliente (ID, Nome, Tags)
- Editar cliente
- Apagar cliente (com opção de **cascata**, removendo acessos vinculados)

### Acessos por cliente
- **SSH**
  - Cadastrar (alias, nome, host, **porta**, usuário, tags)
  - Abrir com 1 clique
  - Editar e apagar
- **RDP**
  - Cadastrar (alias, nome, host, **porta**, domínio opcional, usuário, tags)
  - Abrir com 1 clique (gera `.rdp`)
  - Editar e apagar
  - Porta customizada gravada corretamente via `server port:i:PORT`
- **HTTPS**
  - Cadastrar URL completa (ex.: `https://firewall.voceconfia.com.br:4444`)
  - Porta padrão **443** caso não seja informada
  - Abrir no navegador padrão
  - Editar e apagar

### Interface
- Tema escuro (azul/preto)
- Lista de clientes na lateral (NavigationSplitView)
- Ações rápidas (Adicionar / Abrir / Editar / Apagar)
- (Opcional) gráficos/estatísticas se `LogParser` estiver ativo

---

## 🧩 Tecnologias

- SwiftUI
- Combine (para `ObservableObject` / `@Published`)
- Charts (para gráfico, quando habilitado)
- AppKit (via `NSWorkspace` para abrir SSH/HTTPS e `.rdp`)

---

## ✅ Requisitos

- macOS (Apple Silicon / Intel)
- Xcode 15+ (recomendado)
- Swift 5.9+ (recomendado)

---

## 🚀 Como rodar (desenvolvimento)

1. Clone o repositório:

   ```bash
   git clone <URL_DO_REPO>
   cd <PASTA_DO_REPO>
   ```

2. Abra no Xcode:
   - Abra o `.xcodeproj` (ou `.xcworkspace` se existir)

3. Selecione o Target macOS

4. Execute:
   - `Run` (⌘R)

---

## 🗂 Persistência de dados (CSV)

O app cria e mantém os arquivos em:

```
~/.menu-acessos/
```

Arquivos criados:

- `clients.csv`
- `ssh.csv`
- `rdp.csv`
- `urls.csv`
- `rdpfiles/` (pasta para arquivos `.rdp` gerados)

> Importante: o CSV é **simples** (split por vírgula). Evite vírgulas dentro dos campos.

---

## 📄 Formatos dos arquivos

### 1) `clients.csv`

Header:
```
client_id,client_name,tags
```

Exemplo:
```
scma,Santa Casa,prod;hospital
```

---

### 2) `ssh.csv`

Header:
```
alias,client_id,server_name,host,port,user,tags
```

Exemplo:
```
scma-ssh01,scma,Servidor Linux,10.0.0.10,2222,root,infra
```

---

### 3) `rdp.csv`

Header:
```
alias,client_id,server_name,host,port,domain,user,tags
```

Exemplo:
```
scma-rdp01,scma,Terminal Server,10.0.0.20,3390,SCMA,administrator,rdp
```

---

### 4) `urls.csv` (HTTPS)

Header:
```
alias,client_id,name,host,port,path,tags
```

Exemplo:
```
fw-web01,scma,Firewall,firewall.voceconfia.com.br,4444,/,seguranca
```

Regras:
- Se a porta não for informada, usar **443**
- `path` vazio vira `/`

---

## 🔗 Como a ação “Abrir” funciona

### SSH
O app abre uma URL do tipo:

```
ssh://usuario@host:porta
```

O macOS encaminha para o handler padrão configurado (Terminal/iTerm/cliente SSH).  
➡️ Isso evita permissões extras e automações.

---

### RDP
O app gera um arquivo `.rdp` em:

```
~/.menu-acessos/rdpfiles/
```

E abre automaticamente com o app padrão de RDP do macOS (ex.: Microsoft Remote Desktop).

Inclui a porta via:

```
server port:i:PORT
```

---

### HTTPS
O app abre no navegador padrão:

```
https://host:porta/path
```

---

## 🎨 Ícone do app (AppIcon) — macOS

O macOS exige múltiplos tamanhos no `AppIcon.appiconset`.

Tamanhos comuns:

- 16×16 (1x)
- 32×32 (2x de 16)
- 32×32 (1x)
- 64×64 (2x de 32)
- 128×128 (1x)
- 256×256 (2x de 128)
- 256×256 (1x)
- 512×512 (2x de 256)
- 512×512 (1x)
- 1024×1024 (2x de 512)

### Onde configurar
No Xcode:
- `Assets.xcassets` → `AppIcon`

### Erro clássico
Se aparecer algo como:

> `logo.png is 1024x1024 but should be 16x16`

Significa que um PNG grande foi colocado em slot pequeno.  
Substitua pelo tamanho correto em cada slot.

---

## 🛠 Troubleshooting

### 1) `Expressions are not allowed at the top level`
Você tem Views/chamadas soltas fora de um `struct View`.

✅ Correção:
Garanta que `Image(...)`, `Text(...)`, `.frame(...)` etc. estejam dentro de:

```swift
struct ContentView: View {
    var body: some View {
        // Views aqui
    }
}
```

---

### 2) `Result of call to 'frame(...)' is unused`
Normalmente aparece quando `.frame(...)` está “solto”, não encadeado com uma View.

✅ Exemplo correto:

```swift
Image("logo")
  .resizable()
  .frame(width: 40, height: 40)
```

---

### 3) `Picker: the selection "" is invalid...`
A seleção atual não corresponde a nenhum `.tag(...)` existente.

✅ Correção recomendada:
- Selecione clientes por **ID** (String) e use `.tag(...)` coerente com o tipo da seleção.

---

## 🧭 Estrutura do projeto (visão geral)

Arquivos típicos:

- `ContentView.swift`  
  UI principal: lista de clientes, listas de acessos e botões de ação.

- `Models.swift`  
  Modelos: `Client`, `SSHServer`, `RDPServer`, `URLAccess`.

- `CSVStore.swift`  
  Persistência: leitura, escrita e CRUD dos CSVs em `~/.menu-acessos/`.

- `SSHLauncher.swift`  
  Abre SSH via `ssh://...` usando `NSWorkspace`.

- `RDPFileWriter.swift`  
  Gera `.rdp` (com porta custom) e abre via `NSWorkspace`.

- `URLLauncher.swift`  
  Abre URLs HTTPS via `NSWorkspace`.

- `Add*.swift` / `Edit*.swift`  
  Telas de cadastro e edição.

---

## 🔒 Segurança

- O app **não armazena senhas**
- Os dados ficam em `~/.menu-acessos/` no seu usuário do macOS
- Recomenda-se proteger o dispositivo e o usuário com senha/Touch ID

---

## 🗺 Roadmap

- Export/Import via UI
- Busca global por nome/tags
- Favoritos
- Validação visual de host/porta/URL
- Criptografia opcional do storage local
- Sync opcional (ex.: iCloud Drive), se desejado

---

## 🤝 Contribuindo

1. Faça um fork
2. Crie uma branch:

   ```bash
   git checkout -b feature/minha-melhoria
   ```

3. Commit:

   ```bash
   git commit -m "feat: minha melhoria"
   ```

4. Push:

   ```bash
   git push origin feature/minha-melhoria
   ```

5. Abra um Pull Request
