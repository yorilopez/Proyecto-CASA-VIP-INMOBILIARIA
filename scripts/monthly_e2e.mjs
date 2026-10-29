import fs from 'node:fs/promises';import path from 'node:path';import{spawn}from'node:child_process';import{createWriteStream}from'node:fs';import{fileURLToPath,pathToFileURL}from'node:url';import{createRequire}from'node:module';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),req=createRequire(process.env.CASA_VIP_UI_TOOLS+'/package.json');const imported=await import(pathToFileURL(req.resolve('playwright')).href),{chromium}=imported.default??imported;
const folder=root+'/evidence/revision_0_5_0',out=folder+'/screens';await fs.mkdir(out,{recursive:true});
const log=createWriteStream(folder+'/monthly-server.txt');
const server=spawn(process.env.JAVA_HOME+'/bin/java',['-jar',root+'/backend/target/casa-vip-backend-0.5.0.jar','--server.port=18081','--app.nio2=true','--spring.profiles.active=demo','--spring.datasource.url=jdbc:h2:mem:monthly_ui;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1','--app.private-root='+root+'/cache/monthly-ui-private'],{cwd:root+'/cache',windowsHide:true});server.stdout.pipe(log,{end:false});server.stderr.pipe(log,{end:false});
let browser,page;const errors=[];let token;
const now=new Date(Date.now()-5*3600000),month=now.toISOString().slice(0,7),previous=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()-1,1)).toISOString().slice(0,7);
async function api(p){const r=await fetch('http://127.0.0.1:18081/api'+p,{headers:{Authorization:'Bearer '+token}});if(!r.ok)throw Error(p+' HTTP '+r.status);return r.json();}
try{
 for(let i=0;i<100;i++){try{if((await fetch('http://127.0.0.1:18081/api/health')).ok)break;}catch{}await new Promise(r=>setTimeout(r,400));}
 const login=await fetch('http://127.0.0.1:18081/api/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@casavip.pe',password:'CasaVIP-demo-2026!'})});token=(await login.json()).token;if(!token)throw Error('No se pudo iniciar el escenario mensual');
 let all=[],ops=[];for(let i=0;i<40;i++){all=await api('/clients');ops=await api('/reservations');if(all.length===38&&ops.length===20)break;await new Promise(r=>setTimeout(r,200));}if(all.length!==38||ops.length!==20)throw Error('No se cargaron los escenarios ampliados: '+all.length+'/'+ops.length);
 const old=await api('/reservations?month='+previous);if(old.length!==3)throw Error('El mes anterior debe tener separación venta y liberación');
 const potential=await api('/clients?month='+month+'&category=POTENCIAL');if(potential.length!==3)throw Error('Se esperaban tres clientes potenciales del proyecto demo');
 browser=await chromium.launch({headless:true});page=await browser.newPage({viewport:{width:430,height:900},deviceScaleFactor:1,acceptDownloads:true});page.on('pageerror',e=>errors.push(String(e)));
 await page.goto('http://127.0.0.1:18081',{waitUntil:'networkidle'});await page.waitForTimeout(900);const sem=page.locator('flt-semantics-placeholder');if(await sem.count())await sem.dispatchEvent('click');
 async function click(name){let el=page.getByRole('button',{name,exact:true});if(!await el.count())el=page.getByText(name,{exact:true});await el.last().click();await page.waitForTimeout(350);}
 async function shot(name){await page.waitForTimeout(300);await page.screenshot({path:out+'/'+name+'.png'});}
 async function enter(name,value){const el=page.getByRole('textbox',{name:new RegExp('^'+name)});await el.last().click();await page.waitForTimeout(150);await page.keyboard.press('Control+A');await page.keyboard.type(value,{delay:20});await page.waitForTimeout(120);}
 await enter('Correo corporativo','admin@casavip.pe');await enter('Contraseña','CasaVIP-demo-2026!');await click('Ingresar');await page.getByText('Precios',{exact:true}).waitFor();
 await click('Clientes');await click('Todos los clientes');await click('Clientes potenciales');await page.getByText('3 clientes',{exact:true}).waitFor();await shot('22_clientes_potenciales');
 await click('Operaciones');await page.getByRole('button',{name:'Filtrar operaciones',exact:true}).click();await page.getByText('Mostrar',{exact:true}).waitFor();await shot('23_filtros_operaciones');
 await click('Todas las operaciones');await click('Ventas');await click('Aplicar filtros');await page.getByText('2 ventas',{exact:true}).waitFor();await shot('24_ventas_mes_actual');
 await page.getByRole('button',{name:/^Mi cuenta/}).click();await page.getByRole('menuitem',{name:'Historiales comerciales',exact:true}).click();
 await click('Filtrar historial');await click('Todos los usuarios');await click('Andrea Demo');await click('Aplicar filtros');await shot('25_historial_usuario');
 const history=await api('/admin/history?month='+month+'&user=1');if(history.length===0)throw Error('El historial de Andrea debe contener registros demo');
 await page.getByRole('button',{name:/Ver cambio/}).first().click();await page.getByText('Anterior',{exact:true}).first().waitFor();await page.getByText('Nuevo',{exact:true}).first().waitFor();await shot('26_historial_comparacion');
 const body=await page.locator('body').ariaSnapshot();if(body.includes('password_hash')||body.includes('ruta_privada')||body.includes('"anterior":'))throw Error('El historial muestra estructura técnica');
 await click('Cerrar');await click('Operaciones');await page.getByRole('button',{name:'Filtrar operaciones',exact:true}).click();await page.getByRole('checkbox',{name:'Todos los períodos',exact:true}).check();await click('Aplicar filtros');await shot('27_operaciones_todos_periodos');
 if(errors.length)throw Error(errors.join('\n'));
 await fs.writeFile(folder+'/monthly-verification.json',JSON.stringify({ok:true,clients:all.length,operations:ops.length,currentMonth:month,previousMonth:previous,previousOperations:old.length,potentialClients:potential.length,userHistory:history.length,visualHistory:true,errors,completed:new Date().toISOString()},null,2));
}catch(e){process.exitCode=1;console.error(e);await fs.writeFile(folder+'/monthly-error.txt',String(e));if(page){await fs.writeFile(folder+'/monthly-dom.txt',await page.locator('body').ariaSnapshot());await page.screenshot({path:folder+'/monthly-error.png'});}}finally{if(browser)await browser.close();server.kill();log.end();}
