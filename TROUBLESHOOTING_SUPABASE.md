# 🔧 Troubleshooting: "Invalid API Key" no Supabase

## 🎯 Problema
Ao tentar criar conta, aparece o erro: **"invalid api key"**

---

## ✅ SOLUÇÕES

### **1. Verificar arquivo .env**

Confirme que o arquivo `.env` na raiz do projeto contém:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Ações:**
- ✅ Verificar se o arquivo `.env` existe na raiz do projeto
- ✅ Verificar se não há espaços extras antes/depois das chaves
- ✅ Verificar se não há aspas nas variáveis

---

### **2. Obter Chaves Corretas do Supabase**

#### **Passo a passo:**

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **Settings** (⚙️) → **API**
4. Copie:
   - **Project URL** → `SUPABASE_URL`
   - **Project API keys** → **anon public** → `SUPABASE_ANON_KEY`

**⚠️ IMPORTANTE:** Use a chave `anon public`, NÃO a `service_role`!

---

### **3. Verificar se as configurações do Supabase estão corretas**

No painel do Supabase:

1. **Authentication** → **Providers**
   - ✅ Certifique-se que **Email** está habilitado
   - ✅ Desabilite "Confirm email" se estiver testando (opcional)

2. **Authentication** → **Settings**
   - ✅ Verifique se "Enable email signups" está marcado

---

### **4. Recarregar variáveis de ambiente**

Após alterar o `.env`:

```bash
# Pare o app (Ctrl+C ou Q)
# Limpe o build
flutter clean

# Rebuild
flutter pub get
flutter run
```

---

### **5. Verificar logs do app**

Com as alterações que fiz, você verá logs no console:

```
[Supabase] URL carregada: https://rpbqquxnnpsiyredhkvv...
[Supabase] Key carregada: eyJhbGciOiJIUzI1NiI...
[Supabase] Cliente inicializado com sucesso!
```

Se não aparecer esses logs, o `.env` não está sendo carregado.

---

### **6. Verificar se o .env está no pubspec.yaml**

Confirme que `pubspec.yaml` tem:

```yaml
flutter:
  uses-material-design: true

  assets:
    - .env  # ← Deve estar aqui!
```

---

### **7. Testar chaves manualmente**

Crie um teste rápido no `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  print('URL: ${dotenv.env['SUPABASE_URL']}');
  print('KEY: ${dotenv.env['SUPABASE_ANON_KEY']}');

  // Se aparecer "null", o .env não está carregando
}
```

---

## 🔍 CHECKLIST DE DIAGNÓSTICO

Execute este checklist:

- [ ] Arquivo `.env` existe na raiz do projeto
- [ ] `.env` está listado no `pubspec.yaml` → `assets`
- [ ] Chaves foram copiadas corretamente do painel do Supabase
- [ ] Não há espaços ou aspas nas variáveis do `.env`
- [ ] Authentication está habilitado no painel do Supabase
- [ ] Fez `flutter clean` e `flutter run` após alterar `.env`
- [ ] Logs aparecem no console mostrando que as chaves foram carregadas

---

## 🚨 CAUSAS COMUNS

### **Causa 1: Chave errada**
❌ Você copiou a `service_role key` ao invés da `anon public key`

**Solução:** Copie a chave **anon public** do painel do Supabase

---

### **Causa 2: .env não carrega**
❌ O arquivo `.env` não está sendo incluído no build

**Solução:**
1. Verifique se está em `pubspec.yaml` → `flutter` → `assets`
2. Execute `flutter clean` e `flutter pub get`
3. Reinstale o app no dispositivo

---

### **Causa 3: URL incorreta**
❌ URL do Supabase está incompleta ou com erro de digitação

**Solução:** A URL deve ser exatamente como no painel:
```
https://seu-projeto-id.supabase.co
```

---

### **Causa 4: Projeto Supabase pausado**
❌ O projeto pode estar pausado no plano free

**Solução:**
1. Acesse https://supabase.com/dashboard
2. Verifique se o projeto está ativo
3. Se pausado, clique em "Restore project"

---

## 💡 TESTE RÁPIDO

Execute no terminal:

```bash
# Ver conteúdo do .env
cat .env

# Deve mostrar:
# SUPABASE_URL=https://...
# SUPABASE_ANON_KEY=eyJ...
```

Se não mostrar nada, o arquivo não existe ou está vazio.

---

## 📞 AINDA NÃO FUNCIONA?

Se após todas as verificações ainda não funcionar:

1. **Crie um novo projeto no Supabase:**
   - https://supabase.com/dashboard
   - New Project
   - Copie as novas chaves para o `.env`

2. **Verifique se não há firewall bloqueando:**
   - O dispositivo tem acesso à internet?
   - Teste abrindo https://seu-projeto.supabase.co no navegador

3. **Execute o app com logs:**
   ```bash
   flutter run -v
   ```
   E envie os logs do erro completo

---

## ✅ APÓS RESOLVER

Quando funcionar, você verá:
- Usuário criado com sucesso no painel do Supabase
- Dashboard do app carrega normalmente
- Nenhum erro no console

---

**Dica:** Use o `.env.example` como referência para o formato correto!
