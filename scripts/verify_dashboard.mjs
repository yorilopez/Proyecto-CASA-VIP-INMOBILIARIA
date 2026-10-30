import fs from 'node:fs/promises';
export async function verifyDashboard({page,root,click,enter,capture}) {
  const out=root+'/evidence/revision_0_6_0';
  await capture('22_dashboard_mensual');
  const downloads=[];
  for(const [label,ext] of [['PDF','pdf'],['Excel','xlsx'],['TXT','txt']]){
    await click('Descargar reporte mensual');
    await page.getByRole('button',{name:new RegExp('^'+label+'$')}).click();
    const pending=page.waitForEvent('download');await click('Guardar reporte');
    const file=await pending;await file.saveAs(out+'/'+file.suggestedFilename());downloads.push(file.suggestedFilename());
    if(!file.suggestedFilename().endsWith('.'+ext))throw Error('Formato incorrecto: '+ext);
  }
  await page.getByRole('button',{name:'Ver historial de cambios'}).click();
  await capture('23_historial');
  await page.getByText(/Todas las acciones.*·/).first().click();
  await capture('24_filtros_historial');await click('Aplicar filtros');
  await page.getByRole('button',{name:/^Mi cuenta/}).click();await page.getByRole('menuitem',{name:'Cerrar sesión',exact:true}).click();
  await page.getByRole('textbox',{name:/^Correo corporativo/}).click();
  if(await page.locator('input:focus').inputValue()!=='')throw Error('Cerrar sesión conservó el correo');
  await enter('Correo corporativo','responsable@casavip.pe');await enter('Contraseña','CasaVIP-demo-2026!');
  await page.getByRole('checkbox',{name:'Mantener sesión iniciada'}).click();await click('Ingresar');
  await page.reload({waitUntil:'networkidle'});await page.waitForTimeout(1500);
  const sem=page.locator('flt-semantics-placeholder');if(await sem.count())await sem.dispatchEvent('click');
  await page.getByText('Dashboard',{exact:true}).waitFor();
  await click('Dashboard');await capture('25_dashboard_responsable');
  await fs.writeFile(out+'/dashboard.json',JSON.stringify({ok:true,formats:downloads,rememberRestored:true,clearedCredentials:true,completed:new Date().toISOString()},null,2));
}
