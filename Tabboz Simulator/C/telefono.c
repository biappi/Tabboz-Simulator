// Tabboz Simulator
// (C) Copyright 1999 by Andrea Bonomi
// Iniziato il 31 Marzo 1999
// 31 Maggio 1999 - Conversione
//                                              Tabbozzo -> Tabbozza

/*
	 This file is part of Tabboz Simulator.

	 Tabboz Simulator is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Nome-Programma is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
	 along with Nome-Programma.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "os.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "zarrosim.h"

__attribute__((unused)) static char sccsid[] = "@(#)" __FILE__ " " VERSION " (Andrea Bonomi) " __DATE__;

// ------------------------------------------------------------------------------------------
//  Controlla se e' un giorno di vacanza...
// ------------------------------------------------------------------------------------------

static int CellularVacanza(HWND hDlg)
{
	if ( x_vacanza != 2 )
		return(0);
	else {
		MessageBox( hDlg,
		  "Stranamente, in un giorno di vacanza, il negozio e' chiuso...",
				"Telefonino", MB_OK | MB_ICONINFORMATION);
		return(-1);
	}
}

// ------------------------------------------------------------------------------------------
//  Compra Cellulare
// ------------------------------------------------------------------------------------------

# pragma argsused
BOOL FAR PASCAL   CompraCellulare(HWND hDlg, WORD message, WORD wParam, LONG lParam) 	/* 31 Marzo 1999 */
{
		 int  i;
static int  scelta = 0;

	 if (message == WM_INITDIALOG) {
		SetDlgItemText(hDlg, 104, MostraSoldi(Soldi));
		for (i=0;i<3;i++)
			SetDlgItemText(hDlg, 120+i, MostraSoldi(CellularMem[i].prezzo));
		return(TRUE);
	 } else if (message == WM_COMMAND) {

		switch (LOWORD(wParam)) {
		case 110:
		case 111:
		case 112:
			scelta = LOWORD(wParam) - 110;
			return(TRUE);

		case IDCANCEL:
			EndDialog(hDlg, TRUE);
			return(TRUE);

		case IDOK:
			if (Soldi < CellularMem[scelta].prezzo) { // Controlla se ha abbastanza soldi...
				nomoney(hDlg,CELLULRABBONAM);
				EndDialog(hDlg, TRUE);
				return(TRUE);
			}

			Soldi-=CellularMem[scelta].prezzo;
			CellularData=CellularMem[scelta];
			Fama+=CellularMem[scelta].fama;
         if (Fama > 100) Fama=100;

			EndDialog(hDlg, TRUE);
			return(TRUE);

		default:
			return(TRUE);
		}
	 }

	 return(FALSE);
}


// ------------------------------------------------------------------------------------------
//  Abbonamento
// ------------------------------------------------------------------------------------------


# pragma argsused
BOOL FAR PASCAL   AbbonaCellulare(HWND hDlg, WORD message, WORD wParam, LONG lParam) 	/* 31 Marzo 1999 */
{
		 char tmp[128];
		 int  i;
static int  scelta = 0;

	 if (message == WM_INITDIALOG) {
		SetDlgItemText(hDlg, 104, MostraSoldi(Soldi));
		if (AbbonamentData.creditorest > -1) {
			sprintf(tmp, "%s", AbbonamentData.nome.UTF8String);
			SetDlgItemText(hDlg, 105, tmp);
		}
		for (i=0;i<9;i++)
			SetDlgItemText(hDlg, 110+i, MostraSoldi( AbbonamentMem[i].prezzo));
		return(TRUE);
	 } else if (message == WM_COMMAND) {

		switch (LOWORD(wParam)) {

		case 110:
		case 111:
		case 112:
		case 113:
		case 114:
		case 115:
		case 116:
		case 117:
		case 118:
			scelta = LOWORD(wParam) - 110;
			return(TRUE);

		case IDCANCEL:
			EndDialog(hDlg, TRUE);
			return(TRUE);

		case IDOK:
            [Tabboz.global compraAbbonamento:scelta :hDlg];
			return(TRUE);

		default:
			return(TRUE);
		}
	 }

	 return(FALSE);
}




// ------------------------------------------------------------------------------------------
//  Cellulare
// ------------------------------------------------------------------------------------------

void AggiornaCell(HWND hDlg)
{
char tmp[128];
		SetDlgItemText(hDlg, 104, MostraSoldi(Soldi));

		if (CellularData.stato > -1) {
			sprintf(tmp, "%s", CellularData.nome.UTF8String);
			SetDlgItemText(hDlg, 120, tmp);
		} else {
			SetDlgItemText(hDlg, 120, NULL);
		}

		if (AbbonamentData.creditorest > -1) {
			sprintf(tmp, "%s", AbbonamentData.nome.UTF8String);
			SetDlgItemText(hDlg, 121, tmp);  												// Abbonamento
			SetDlgItemText(hDlg, 122, MostraSoldi(AbbonamentData.creditorest));	// Credito
		} else {
			SetDlgItemText(hDlg, 121, NULL);
			SetDlgItemText(hDlg, 122, NULL);
		}
}


#pragma argsused
BOOL FAR PASCAL        Cellular(HWND hDlg, WORD message, WORD wParam, LONG lParam) 	/* 31 Marzo 1999 */
{
	 char 			tmp[128];
	 FARPROC       lpproc;
	 long			   offerta;
	 int				scelta;
	 if (message == WM_INITDIALOG) {
		AggiornaCell(hDlg);
		return(TRUE);
	 } else if (message == WM_COMMAND) {
		switch (LOWORD(wParam)) {
		case 110:
			if (CellularVacanza(hDlg) == 0) {
				lpproc = MakeProcInstance(CompraCellulare, hInst);
				DialogBox(hInst,
					MAKEINTRESOURCE(COMPRACELLULAR),
					hDlg,
					lpproc);
				FreeProcInstance(lpproc);
				AggiornaCell(hDlg);
				}
			return(TRUE);

		case 111:
			if (CellularVacanza(hDlg) == 0) {
				if (CellularData.stato > -1) {
					offerta=CellularData.prezzo/2 + 15;
					sprintf(tmp,"Ti posso dare %s per il tuo telefonino... vuoi vendermelo ?",MostraSoldi(offerta));
					scelta=MessageBox( hDlg,
					  tmp,
					  "Telefonino", MB_YESNO | MB_ICONQUESTION);
					if (scelta == IDYES) {
					  CellularData.stato=-1;
					  Soldi+=offerta;
					} else
					  MessageBox( hDlg,
						 "Allora vai a farti fottere, pirletta !",
						 "Telefonino", MB_OK | MB_ICONINFORMATION);
				} else {
					MessageBox( hDlg,
					  "Che telefonino vuoi vendere, pirletta ?",
					  "Telefonino", MB_OK | MB_ICONINFORMATION);
					}
				AggiornaCell(hDlg);
				}
			return(TRUE);

		case 112:
			if (CellularVacanza(hDlg) == 0) {
				lpproc = MakeProcInstance(AbbonaCellulare, hInst);
				DialogBox(hInst,
					MAKEINTRESOURCE(CELLULRABBONAM),
					hDlg,
					lpproc);
				FreeProcInstance(lpproc);
				AggiornaCell(hDlg);
			}
			return(TRUE);

		case 150:
		case IDOK:
		case IDCANCEL:
			EndDialog(hDlg, TRUE);
			return(TRUE);

		default:
			return(TRUE);
		}
	 }

	 return(FALSE);
}





