# بات 0xKia — قالب استقرار روی Railway

دپلوی ایجنت هوشمند **0xKia** روی Railway به‌صورت سرویس Worker با وضعیت پایدار (Persistent State)، همراه کیف پول تست‌نت Radius، ابزارهای پرداخت x402 و لایه کشف ایجنت (A2A).

> **منشأ این مخزن:** این پروژه بر اساس قالب `radius-hermes-railway-template` از سازمان `radius-workshop` ساخته شده و با برند **0xKia** بازنویسی برند (Rebrand) شده است. Runtime زیرین، فریمورک متن‌باز `hermes-agent` است که از سورس پین‌شده نصب می‌شود.

---

## فهرست

- [معرفی بات](#معرفی-بات)
- [چه چیزهایی می‌گیرید؟](#چه-چیزهایی-می‌گیرید)
- [نحوه کار](#نحوه-کار)
- [نکته مهم: قراردادهای فنی فریمورک](#نکته-مهم-قراردادهای-فنی-فریمورک)
- [شروع سریع](#شروع-سریع)
- [متغیرهای الزامی](#متغیرهای-الزامی)
- [راه‌اندازی تلگرام / دیسکورد / اسلک](#راه‌اندازی-تلگرام--دیسکورد--اسلک)
- [متغیرهای پیشنهادی](#متغیرهای-پیشنهادی)
- [کیف پول Radius](#کیف-پول-radius)
- [پرداخت‌های x402](#پرداخت‌های-x402)
- [پروکسی خروجی (Egress)](#پروکسی-خروجی-egress)
- [ارتباط ایجنت‌به‌ایجنت (A2A)](#ارتباط-ایجنت‌به‌ایجنت-a2a)
- [ثبت ERC-8004 و هویت on-chain](#ثبت-erc-8004-و-هویت-on-chain)
- [کشف ایجنت (/.well-known)](#کشف-ایجنت-well-known)
- [استقرار روی Kubernetes با Helm](#استقرار-روی-kubernetes-با-helm)
- [لاگ‌ها در Railway](#لاگ‌ها-در-railway)
- [تست‌ها](#تست‌ها)
- [انتگرال Linear](#انتگرال-linear)
- [ساختار مخزن](#ساختار-مخزن)

---

## معرفی بات

**0xKia** دستیار هوشمند پرداخت‌ها و تعامل روی شبکه Radius است:

- گفتگوی طبیعی در تلگرام، دیسکورد یا اسلک
- مدیریت کیف پول تست‌نت Radius (آدرس، موجودی SBC، ارسال توکن، وضعیت تراکنش)
- پرداخت‌های کنترل‌شده به APIهای x402 با دفتر کل (Ledger) دائمی
- ارتباط خودکار با ایجنت‌های دیگر از طریق A2A و هویت `did:web`
- حافظه پایدار و مهارت‌های قابل توسعه

## چه چیزهایی می‌گیرید؟

- گیت‌وی 0xKia به‌صورت Worker روی Railway با بوت‌استرپ خودکار از متغیرهای محیطی
- وضعیت پایدار روی Volume در مسیر `/data` (حالت پیش‌فرض وضعیت: `/data/.0xkia`)
- پشتیبانی از **تلگرام، دیسکورد یا اسلک** (حداقل یکی الزامی است)
- کیف پول تست‌نت Radius داخلی — در اولین اجرا ساخته و از Faucet شارژ می‌شود
- لایه کشف ایجنت در `/.well-known/*`: ثبت ERC-8004، کارت A2A و کشف مهارت‌ها
- ارتباط A2A با دو حالت اجرا: مستقیم (inline) و واگذارشده (webhook)
- هویت رمزنگاری‌شده پایدار بر اساس keystore کیف پول radius-cli (برای امضای JWT و on-chain)
- ابزارهای تأیید و صدور توکن KYA (`kya_validate_claims` و `generate_kya_token`) با کلید P-256 پایدار
- لاگ ساخت‌یافته JSON از سرور ایجنت + ارسال لاگ‌های Runtime به خروجی Railway
- مهارت‌های Radius فروشنده‌شده در ایمیج: `radius-dev`، `x402`، `dripping-faucet`، `sell-api`
- ابزارهای کیف پول: `radius_wallet_address`، `radius_balance`، `radius_send_sbc`، `radius_tx_status`
- ابزار `feedback_ledger` برای گزارش بازخوردهای 👍/👎 کاربران روی پاسخ‌های اسلک

## نحوه کار

1. متغیرهای لازم را در Railway تنظیم می‌کنید.
2. در اولین اجرا، `scripts/entrypoint.sh` وضعیت 0xKia را زیر `/data/.0xkia` مقداردهی می‌کند، کیف پول Radius را می‌سازد، مهارت‌ها و پلاگین‌های همراه را نصب می‌کند.
3. در اجراهای بعدی همان وضعیت پایدار استفاده می‌شود (نشانه‌گذاری با `.initialized`).
4. کانتینر سرور ایجنت Python/FastAPI و گیت‌وی را به‌صورت موازی اجرا می‌کند.
5. اگر نسخه قدیمی حالت در `/data/.hermes` باشد، به‌صورت خودکار به `/data/.0xkia` منتقل می‌شود.

## نکته مهم: قراردادهای فنی فریمورک

بازنویسی برند به 0xKia کامل است، اما چند نام **قرارداد فنی فریمورک زیرین** (پکیج `hermes-agent` نصب‌شده از سورس پین‌شده) حفظ شده‌اند تا عملکرد خراب نشود:

| نام حفظ‌شده | دلیل |
|---|---|
| `HERMES_HOME` (نام متغیر؛ مقدار جدید: `/data/.0xkia`) | فریمورک زیرین این نام را برای پیدا کردن وضعیت می‌خواند |
| دستور `hermes` (مثلاً `hermes gateway`) | باینری واقعی نصب‌شده از پکیج upstream |
| `HERMES_INFERENCE_PROVIDER`، `HERMES_MAX_ITERATIONS`، `HERMES_TOOL_PROGRESS_MODE` و مشابه | متغیرهایی که خود فریمورک می‌خواند |
| `HERMES_SESSION_PLATFORM` و مشابه | متغیرهایی که Runtime برای پلاگین‌ها تنظیم می‌کند |
| هدر `X-Hermes-Session-Id` | قرارداد API گیت‌وی برای پیوستگی نشست |
| `hermes_feedback` | شناسه دکمه بازخوردی که Runtime در اسلک رندر می‌کند |
| نام فایل `HERMES.md` | فایل کانتکست پروژه با قرارداد نام فریمورک (محتوای آن هویت 0xKia را تعریف می‌کند) |

تمام متغیرهای **متعلق به این قالب** به پیشوند `KIA_` تغییر نام داده‌اند (نسخه قدیمی `HERMES_*` به‌عنوان fallback پذیرفته می‌شود):

| نام جدید | نام قدیمی | کاربرد |
|---|---|---|
| `KIA_API_KEY` | `HERMES_API_KEY` | احراز هویت سرور ایجنت و پل A2A |
| `KIA_URL` | `HERMES_URL` | آدرس API سازگار با OpenAI گیت‌وی محلی |
| `KIA_TIMEOUT` | `HERMES_TIMEOUT` | Timeout پل مستقیم (ثانیه) |
| `KIA_SERVICE_ROLE` | `HERMES_SERVICE_ROLE` | نقش سرویس (`agent` یا `egress`) |
| `KIA_FORWARD_LOG_FILES` | `HERMES_FORWARD_LOG_FILES` | ارسال فایل‌های لاگ به خروجی |
| `KIA_FORWARD_GATEWAY_LOG` | `HERMES_FORWARD_GATEWAY_LOG` | ارسال `gateway.log` اضافه |
| `KIA_DISABLED_TOOLSETS` | `HERMES_DISABLED_TOOLSETS` | غیرفعال‌سازی ابزارها |
| `KIA_BACKGROUND_REVIEW` | `HERMES_BACKGROUND_REVIEW` | بازبینی پس‌زمینه |
| `KIA_MEMORY_NOTIFICATIONS` | `HERMES_MEMORY_NOTIFICATIONS` | اعلان‌های حافظه |
| `KIA_X402_TARGET`، `KIA_X402_EXPECTED_OFFER` | `HERMES_X402_*` | داخلی پلاگین x402 |
| `KIA_GIT_REF` | `HERMES_GIT_REF` | آرگومان Build برای پین کردن Runtime |

## شروع سریع

```bash
# 1. پروژه Railway بسازید و یک Volume روی /data اضافه کنید
# 2. این مخزن را به پروژه لینک کنید
railway link

# 3. متغیرهای الزامی را تنظیم کنید (حداقل: یک Provider + یک پلتفرم)
railway variables --set ANTHROPIC_API_KEY=sk-ant-...
railway variables --set HERMES_INFERENCE_PROVIDER=anthropic
railway variables --set LLM_MODEL=<anthropic-model-id>
railway variables --set TELEGRAM_BOT_TOKEN=123456:ABC...

# 4. چک قبل از دیپلوی، سپس استقرار
./deploy.sh
```

`deploy.sh` قبل از ارسال هر چیزی، متغیرهای الزامی را بررسی می‌کند تا خطا را محلی ببینید نه به‌صورت Crash Loop در تولید.

برای شروع از صفر:

```bash
./deploy.sh --reset-state
```

این دستور مسیرهای پایدار روی Volume را قبل از دیپلوی پاک می‌کند:

- `/data/.0xkia` (و مسیر قدیمی `/data/.hermes` در صورت وجود)
- `/data/workspace`
- `/data/.claude`

با این کار حافظه ایجنت، نشست‌ها، وضعیت Pairing، وضعیت ByteRover، فایل‌های Workspace و کیف پول Radius پایدار پاک می‌شوند.

## متغیرهای الزامی

حداقل یک Provider استنتاج (Inference):

| متغیر | توضیح |
|---|---|
| `OPENROUTER_API_KEY` | کلید API اوپن‌روتر |
| `OPENAI_API_KEY` + `OPENAI_BASE_URL` | Provider سازگار با OpenAI |
| `ANTHROPIC_API_KEY` | API مستقیم Anthropic |

حداقل یک پلتفرم پیام‌رسان:

| متغیر | توضیح |
|---|---|
| `TELEGRAM_BOT_TOKEN` | توکن بات تلگرام از @BotFather |
| `DISCORD_BOT_TOKEN` | توکن بات دیسکورد |
| `SLACK_BOT_TOKEN` + `SLACK_APP_TOKEN` | اسلک (هر دو الزامی) |

همچنین متغیرهای هویتی بات:

| متغیر | پیش‌فرض | توضیح |
|---|---|---|
| `AGENT_NAME` | `0xKia` | نام نمایشی در همه نقاط کشف (کارت A2A، ERC-8004، صفحه اصلی) |
| `AGENT_DESCRIPTION` | — | معرفی کوتاه بات |
| `PUBLIC_URL` | خودکار از Railway | آدرس عمومی سرویس |

## راه‌اندازی تلگرام / دیسکورد / اسلک

**تلگرام** — از @BotFather توکن بگیرید و در `TELEGRAM_BOT_TOKEN` قرار دهید. با `/start` به بات پیام دهید؛ Pairing خودکار انجام می‌شود.

**دیسکورد** — در [discord.com/developers/applications](https://discord.com/developers/applications) یک اپلیکیشن بسازید:
1. در تب **Bot** توکن را Reset و کپی کنید → `DISCORD_BOT_TOKEN`
2. در تب **Bot** گزینه‌های **Message Content Intent** و **Server Members Intent** را فعال کنید (Privileged Intents)
3. با OAuth2 URL Generator بات را با اسکوپ `bot` به سرور دعوت کنید
4. شناسه کاربری خودتان را با فعال‌کردن Developer Mode و کلیک راست روی اسم خودتان بگیرید → `DISCORD_ALLOWED_USERS`

**اسلک** — فایل `slack/manifest.json` را در [api.slack.com/apps](https://api.slack.com/apps) با گزینه «From an app manifest» بارگذاری کنید (نام بات: 0xKia). سپس:
- **Bot User OAuth Token** (`xoxb-...`) → `SLACK_BOT_TOKEN`
- **App-Level Token** (`xapp-...` با اسکوپ `connections:write`) → `SLACK_APP_TOKEN`
- Socket Mode در تنظیمات اپ فعال باشد

## متغیرهای پیشنهادی

### Allowlist ها (به‌شدت توصیه می‌شود)

بدون allowlist، گیت‌وی به‌صورت پیش‌فرض هیچ پیامی را نمی‌پذیرد (deny-all):

| متغیر | توضیح |
|---|---|
| `TELEGRAM_ALLOWED_USERS` | شناسه‌های کاربری مجاز در تلگرام |
| `DISCORD_ALLOWED_USERS` | شناسه‌های کاربری مجاز در دیسکورد |
| `SLACK_ALLOWED_USERS` | شناسه‌های عضویت مجاز در اسلک |
| `*_ALLOW_ALL_USERS=true` | باز کردن برای همه (فقط برای تست) |

### Provider و مدل

| متغیر | توضیح |
|---|---|
| `HERMES_INFERENCE_PROVIDER` | Provider استنتاج (`openrouter`، `openai`، `anthropic`) |
| `LLM_MODEL` | شناسه مدل؛ پیش‌فرض یک شناسه OpenRouter/OpenAI است |

## کیف پول Radius

در اولین بوت، `entrypoint.sh` با `radius-cli` کیف پول می‌سازد، آدرس را در `RADIUS_HOME/address` ذخیره می‌کند و (به‌صورت پیش‌فرض) از Faucet تست‌نت شارژ می‌کند.

| متغیر | پیش‌فرض | توضیح |
|---|---|---|
| `RADIUS_NETWORK` | `testnet` | شبکه Radius |
| `RADIUS_RPC_URL` | بر اساس شبکه | RPC سفارشی |
| `RADIUS_SBC_ADDRESS` | بر اساس شبکه | آدرس قرارداد SBC |
| `RADIUS_AUTO_FUND` | `true` | شارژ خودکار از Faucet |
| `RADIUS_CLI_BIN` | `radius-cli` | مسیر باینری CLI |

از داخل چت: «آدرس کیف پول من چیست؟»، «موجودی SBC من را نشان بده»، «۰.۰۰۱ SBC به 0x1234... بفرست».

## پرداخت‌های x402

پلاگین `x402` پرداخت HTTP 402 به APIهای تأییدشده روی تست‌نت Radius را با این ابزارها فراهم می‌کند: `x402_request`، `x402_catalog`، `x402_ledger`، `x402_wallet_status`.

| متغیر | توضیح |
|---|---|
| `X402_MAX_PER_CALL` | سقف پرداخت به‌ازای هر درخواست |
| `X402_ALLOWED_HOSTS` | لیست Hostهای مجاز برای پرداخت |
| `X402_LEDGER_PATH` | مسیر دفتر کل پرداخت‌ها (پایدار) |

## پروکسی خروجی (Egress)

یک سرویس دوم با همان ایمیج، رازهای واقعی را نگه می‌دارد و ایجنت فقط توکن‌های Proxy می‌گیرد. تنظیم روی سرویس ایجنت:

```bash
railway variables --set EGRESS_PROXY_URL=http://0xkia-egress:9090
railway variables --set EGRESS_SECRETS=OPENROUTER_API_KEY,SLACK_BOT_TOKEN
```

- سرویس egress: Config File را روی `/railway.egress.toml` بگذارید و `KIA_SERVICE_ROLE=egress` تنظیم می‌شود به‌صورت خودکار
- متغیر `KIA_SERVICE_ROLE` (قدیمی: `HERMES_SERVICE_ROLE`) نقش سرویس را تعیین می‌کند
- روی Kubernetes، چارت Helm سرویس egress را همراه NetworkPolicy و CA داخلی مستقر می‌کند

## ارتباط ایجنت‌به‌ایجنت (A2A)

سرور ایجنت روی `POST /a2a` پیام‌های JSON-RPC را می‌پذیرد. حالت‌ها با `A2A_MODE`:

| حالت | رفتار |
|---|---|
| `direct` | پردازش inline از طریق API سازگار با OpenAI گیت‌وی (`KIA_API_KEY` لازم است) |
| `delegated` | تحویل به مسیر webhook با HMAC |
| `auto` | مستقیم اگر `KIA_API_KEY` تنظیم شده باشد، وگرنه واگذارشده |

احراز هویت با JWT: توکن‌های خروجی را ایجنت با `generate_a2a_token()` می‌سازد؛ فراخواننده‌های بیرونی باید در `TRUSTED_DIDS` باشند. نشست‌های مدیریتی A2A زیر `/data/.0xkia/a2a-sessions` ذخیره می‌شوند.

## ثبت ERC-8004 و هویت on-chain

ابزارهای `erc8004_register_self`، `erc8004_get_agent` و ابزارهای Registry به‌صورت قطعی ثبت‌نام ایجنت را روی قراردادهای ERC-8004 شبکه Radius انجام می‌دهند. امضا با کلید خصوصی keystore انجام می‌شود و کلید هرگز خارج از radius-cli فاش نمی‌شود.

## کشف ایجنت (/.well-known)

پس از ساخت دامنه عمومی در Railway این مسیرها فعال می‌شوند:

- `/.well-known/agent-card.json` — کارت A2A
- `/.well-known/did.json` — هویت `did:web`
- `/.well-known/skills.json` — مهارت‌های `published: true`
- `/.well-known/jwks.json` — کلید عمومی KYA

## استقرار روی Kubernetes با Helm

```bash
kubectl create namespace 0xkia
kubectl -n 0xkia create secret generic 0xkia-agent \
  --from-literal=OPENROUTER_API_KEY=sk-or-... \
  --from-literal=SLACK_BOT_TOKEN=xoxb-... \
  --from-literal=SLACK_APP_TOKEN=xapp-...
helm install 0xkia deploy/helm/0xkia-agent -n 0xkia \
  -f deploy/helm/0xkia-agent/examples/minimal.yaml
helm test 0xkia -n 0xkia
```

چارت شامل StatefulSet با Volume پایدار، NetworkPolicy، اختیاراً سرویس egress و تست کشف داخلی است. مستندات کامل: `deploy/helm/0xkia-agent/README.md`.

## لاگ‌ها در Railway

دو جریان لاگ مکمل:

- **لاگ سرور ایجنت** (`scripts/agent_server/main.py`): JSON تک‌خطی با فیلدهای `@event`، `@request_id`، `@rpc_method`، `@duration_ms` و ...
- **لاگ‌های Runtime 0xKia**: فایل‌های `${HERMES_HOME}/logs/agent.log` و `errors.log` توسط entrypoint با پیشوند `[0xkia:...]` به خروجی Railway ارسال می‌شوند

فیلترهای مفید: `@event:a2a.request`، `@event:auth.jwt_rejected`، `@request_id:<id>`

## تست‌ها

```bash
python scripts/validate_release.py
ruff check .
python scripts/run_tests.py
```

تست‌های Helm فقط وقتی `helm` نصب باشد اجرا می‌شوند. تست قرارداد پلاگین feedback-ledger فقط داخل ایمیج (که Runtime نصب دارد) اجرا می‌شود.

## انتگرال Linear

با تنظیم `LINEAR_API_KEY` (از Linear → Settings → Security & access)، ایجنت می‌تواند ایشو بسازد، به‌روزرسانی کند، کامنت بگذارد و پروژه‌ها را پرس‌وجو کند. ابزار از `linear-claude-skill` کامپایل‌شده در ایمیج استفاده می‌کند.

## ساختار مخزن

| مسیر | محتوا |
|---|---|
| `scripts/entrypoint.sh` | بوت‌استرپ کامل: حالت، کیف پول، مهارت‌ها، پلاگین‌ها، اجرا |
| `scripts/agent_server/` | سرور FastAPI: کشف، احراز هویت JWT، پل A2A (`kia_client.py`) |
| `scripts/egress/iron_egress.py` | پروکسی خروجی با تزریق Secret |
| `plugins/` | پلاگین‌های همراه (x402، kya-mint، radius-cast، feedback-ledger و ...) |
| `skills/` | مهارت‌های نصب‌شده در هر بوت |
| `erc8004_registry/` | کلاینت Registry ERC-8004 |
| `deploy/helm/0xkia-agent/` | چارت Helm |
| `HERMES.md` | فایل کانتکست پروژه برای ایجنت 0xKia |
| `deploy.sh` | بررسی متغیرها + استقرار Railway |
