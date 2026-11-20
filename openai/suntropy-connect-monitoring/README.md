# Suntropy Connect Monitoring · paquete para el directorio de plugins de OpenAI

ZIP en formato Agent Plugins 1.0.0 para platform.openai.com/plugins (ChatGPT y Codex). Se valida contra los esquemas de `agent-plugins.org/schemas/1.0.0/`.

| Fichero | Qué es |
|---|---|
| `plugin.json` | La ficha: `extensions.com.openai.interface`, los 5+3 casos de prueba en `review.test_cases`, `onboardingSkill` y las notas de versión. |
| `mcp.json` | El servidor `https://connect-gateway.suntropy.ai/monitoring/mcp` (`streamable-http`). El OAuth lo descubre el portal por PRM y RFC 8414. El esquema no admite `auth` en el servidor, y CIMD y DCR ya están publicados. |
| `build.sh` | Copia la skill y el logo del plugin de Claude (una sola fuente) y quita la línea de `diagnosis.md` que remite a los conectores de PVsyst y PV*SOL, porque OpenAI prohíbe dirigir al modelo a otros conectores. Inyecta `DEMO_VIDEO_URL` y genera `dist/suntropy-connect-monitoring-<versión>.zip`. |

```bash
DEMO_VIDEO_URL="https://…" ./openai/suntropy-connect-monitoring/build.sh
```

## Antes de enviar

1. **Gateway con pvsyst-api#138 desplegado:**
   - sin `create_connection`;
   - `openWorldHint: false`;
   - mensaje de licencia neutro para ChatGPT;
   - ruta `/.well-known/openai-apps-challenge`.
   Comprobar con `tools/list` que salen 27 herramientas y ninguna recibe credenciales.
2. **Términos publicados** en `https://www.suntropy.ai/connect/terminos/` (landing#105).
3. **Cuenta de prueba** `plugin-revision@suntropy.ai`:
   - licencia de Connect activa y sin caducidad (desde el 20-nov);
   - una marca conectada con plantas reales y autorizadas;
   - vigilancia de alarmas activada, para que haya histórico;
   - login con correo y contraseña, sin MFA.
   La contraseña no va en el repo.
4. **Vídeo grabado y subido** (ver guion), con su URL en `DEMO_VIDEO_URL`.

## Pasos en el portal

1. **Organización.** En platform.openai.com, comprueba que:
   - la organización está verificada como empresa (Enerlence Software Solutions S.L.);
   - tienes el permiso Apps Management Write;
   - el proyecto es de **residencia global**. Desde un proyecto con residencia en la UE no se pueden enviar plugins MCP.
2. **platform.openai.com/plugins › Upload new or existing plugin.** Elige la identidad de desarrollador y sube el ZIP.
3. **Metadata & Skills.** Revisa los avisos.
   - `category` va como «Productivity». Si el desplegable ofrece «Business» u otra que encaje mejor, cámbiala allí.
   - Si algo falla, corrige `plugin.json`, vuelve a montar el ZIP y súbelo otra vez.
4. **MCPs › Connect.**
   - URL: `https://connect-gateway.suntropy.ai/monitoring/mcp`. Autenticación: OAuth.
   - **Verificación de dominio.** El portal da un token. Ponlo en el `.env` del gateway como `OPENAI_APPS_CHALLENGE=<token>` y reinicia `pvsyst-gateway`. Comprueba que `curl https://connect-gateway.suntropy.ai/.well-known/openai-apps-challenge` devuelve exactamente el token en texto plano y pulsa verificar.
   - Conecta y autoriza con la cuenta de prueba. Espera al escaneo de herramientas y revisa **Issues**.
5. **Review information › Review details.** Introduce las credenciales de la cuenta de prueba y las instrucciones de acceso:
   > Sign in with email and password on the Suntropy login screen that opens during OAuth (no MFA, no email codes). The account has an active Suntropy Connect licence and a connected Huawei FusionSolar account with real plants. To test test case 5, open the returned link while signed in to app.suntropy.ai with the same account.
6. **Submit for review.** Acepta las declaraciones. Solo cabe una revisión activa a la vez. La respuesta llega por correo, y si hay rechazo se recurre contestando a ese correo.
7. Cuando esté aprobado: **Publish plugin**.

## Guion del vídeo (2-3 minutos, en inglés, sin datos de clientes reales a la vista)

1. **ChatGPT › Plugins:** añadir Suntropy Connect Monitoring y pasar por el login de Suntropy (OAuth) con la cuenta de prueba.
2. Preguntar: «How are my solar plants doing today? List the ones with problems first.» Se ve la llamada a `get_monitoring_summary` y la respuesta.
3. Preguntar: «Review the open alarms on my plants…» Se ve la clasificación en act now, check soon y no action.
4. Preguntar: «Is my worst-performing plant producing what it should?» Se ve `get_production_health` y la puntuación de salud.
5. Preguntar: «I want to connect my Huawei FusionSolar account.» Se abre el enlace, aparece el formulario de Huawei en app.suntropy.ai y se explica que las credenciales nunca pasan por el chat. No hace falta enviarlo.
6. Cierre: el conector es solo lectura y nunca escribe en los inversores.

⚠️ Antes de grabar, revisa qué plantas y direcciones salen en pantalla con la cuenta de prueba. Si son de un cliente real, desenfócalas o usa una cuenta cuyos datos puedan mostrarse.
