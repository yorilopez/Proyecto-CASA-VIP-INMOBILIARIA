import fs from 'node:fs/promises';

/** Recorre las funciones de administración con la misma API y navegador de la prueba visual. */
export async function verifyCommercialFlows({page,root,click,enter,capture,reservation}){
  const base='http://127.0.0.1:18080/api';
  async function loginToken(email){const r=await fetch(base+'/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password:'CasaVIP-demo-2026!'})});if(!r.ok)throw Error('No se pudo autenticar la verificación');return(await r.json()).token;}
  const admin=await loginToken('admin@casavip.pe');
  async function api(path,method='GET',data){const r=await fetch(base+path,{method,headers:{Authorization:'Bearer '+admin,'Content-Type':'application/json'},body:data===undefined?undefined:JSON.stringify(data)});if(!r.ok)throw Error(path+' HTTP '+r.status+' '+await r.text());return r.json();}
  const original=await api('/operations/'+reservation.id);const stored=original.documentos.find(d=>d.persona==='Cliente Demostración'&&d.lado==='ANVERSO');
  const replacement=new FormData();replacement.append('file',new Blob([await fs.readFile(root+'/scripts/documento_prueba.png')],{type:'image/png'}),'reemplazo.png');
  const uploaded=await fetch(base+'/clients/'+reservation.cliente_id+'/documents/ANVERSO',{method:'POST',headers:{Authorization:'Bearer '+admin},body:replacement});if(!uploaded.ok)throw Error('No se pudo actualizar el documento de prueba');
  const historical=await fetch(base+'/operations/'+reservation.id+'/documents/'+stored.id,{headers:{Authorization:'Bearer '+admin}});if(!historical.ok)throw Error('Actualizar un documento borró el archivo de una operación anterior');
  // El asesor puede exportar la imagen de su operación, sin acceso al botón de texto y DNI.
  await page.getByRole('button',{name:/Cliente Demostración/}).first().click();await page.waitForTimeout(400);
  if(await page.getByRole('button',{name:'Compartir texto y fotos de DNI',exact:true}).count())throw Error('Asesor no debe compartir el paquete textual');
  await page.mouse.move(220,600);await page.mouse.wheel(0,750);await page.waitForTimeout(300);
  let download=page.waitForEvent('download');await click('Compartir como imagen');await(await download).saveAs(root+'/evidence/revision_0_5_0/screens/operacion_asesor.png');await capture('16_operacion_asesor');
  await page.getByRole('button',{name:/^Notificaciones/}).click();await page.waitForTimeout(300);await capture('17_notificaciones');
  // Cambio de rol a través del login real.
  await page.getByRole('button',{name:/^Mi cuenta/}).click();await page.getByRole('menuitem',{name:'Cerrar sesión',exact:true}).click();await enter('Correo corporativo','admin@casavip.pe');await enter('Contraseña','CasaVIP-demo-2026!');await click('Ingresar');await page.getByText('Precios',{exact:true}).waitFor();
  await click('Usuarios');await click('Agregar usuario');await enter('Nombre','Asesor alta de prueba');await enter('Correo','alta.e2e@example.invalid');await enter('Teléfono','900000111');await enter('Contraseña','Clave-demo-2026!');await click('Guardar');await page.getByText('Asesor alta de prueba',{exact:true}).waitFor();await capture('18_usuarios');
  const created=(await api('/admin/users')).find(u=>u.correo==='alta.e2e@example.invalid');if(!created||created.rol!=='ASESOR'||!created.activo)throw Error('No persistió el usuario creado');
  await page.getByRole('button',{name:/^Mi cuenta/}).click();await page.getByRole('menuitem',{name:'Catálogo y precios',exact:true}).click();
  const csv=root+'/cache/precios_revision.csv';await fs.writeFile(csv,'lote_id,precio,inicial,numero_cuotas\n'+reservation.lote_id+',24000,4000,36\n5,99000,5000,24\n');
  const chooser=page.waitForEvent('filechooser');await click('Importar CSV, Excel o JSON');await(await chooser).setFiles(csv);await page.getByText(/Vista previa/).waitFor();await capture('19_catalogo_vista_previa');await click('Aplicar actualización');await enter('Motivo','Catálogo de prueba actualizado');await click('Confirmar');await page.waitForTimeout(600);
  const lot=await api('/lots/'+reservation.lote_id),op=await api('/operations/'+reservation.id);if(Number(lot.precio)!==24000||Number(op.precio_acordado)!==21000||Number(op.inicial_acordada)!==3000||op.numero_cuotas_acordado!==24)throw Error('Catálogo y condiciones deben ser independientes');
  const soldLot=await api('/lots/5');if(Number(soldLot.precio)!==21000)throw Error('La importación cambió un lote vendido');
  await click('Operaciones');await page.getByRole('button',{name:/Cliente Demostración/}).first().click();await page.mouse.move(220,600);await page.mouse.wheel(0,1100);await page.waitForTimeout(300);await click('Registrar venta');
  const price=page.getByRole('textbox',{name:/^Precio acordado/});await price.first().click();await page.waitForFunction(()=>Number(document.querySelector('input:focus')?.value)===21000,{},{timeout:4000});
  await page.getByRole('checkbox').last().click();await click('Confirmar venta');await page.getByRole('button',{name:'Corregir información',exact:true}).waitFor();await page.waitForTimeout(400);
  const sale=await api('/operations/'+reservation.id);if(sale.estado!=='CONFIRMADA'||Number(sale.venta.precio_final)!==21000||Number(sale.venta.inicial)!==3000||sale.venta.numero_cuotas!==24)throw Error('Venta no conservó condiciones');await capture('20_venta');
  await page.mouse.move(220,600);await page.mouse.wheel(0,1000);await page.waitForTimeout(300);
  const downloads=[];const onDownload=async d=>{downloads.push(d.suggestedFilename());await d.saveAs(root+'/evidence/revision_0_5_0/screens/'+d.suggestedFilename());};page.on('download',onDownload);await click('Compartir texto y fotos de DNI');await page.waitForTimeout(800);page.off('download',onDownload);if(downloads.length!==5||!downloads.some(n=>n.endsWith('.txt')))throw Error('Se esperaban texto y las cuatro imágenes de DNI');
  await page.getByRole('button',{name:/^Mi cuenta/}).click();await page.getByRole('menuitem',{name:'Historiales comerciales',exact:true}).click();await capture('21_historiales');
  const feed=await api('/notifications');if(!feed.items.some(n=>n.tipo==='VENTA'))throw Error('Falta notificación global de venta');if(JSON.stringify(feed).includes('00000991'))throw Error('Avisos globales contienen DNI');
  await fs.writeFile(root+'/evidence/revision_0_5_0/funciones_nuevas.json',JSON.stringify({ok:true,advisorImageOnly:true,userCreated:created.id,catalogPrice:lot.precio,reservationPrice:op.precio_acordado,soldLotUnchanged:true,salePrice:sale.venta.precio_final,saleCount:sale.venta.numero_cuotas,sharedFiles:downloads,globalSaleNotification:true,completed:new Date().toISOString()},null,2));
}
