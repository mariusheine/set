/**
 * Copyright (c) 2015 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.ppmodel.extensions

import org.eclipse.set.toolboxmodel.Bedienung.Bedien_Anzeige_Element
import org.eclipse.set.toolboxmodel.Fahrstrasse.Fstr_Abhaengigkeit
import org.eclipse.set.toolboxmodel.Schluesselabhaengigkeiten.Schluesselsperre
import org.eclipse.set.toolboxmodel.Fahrstrasse.Fstr_Fahrweg
import static extension org.eclipse.set.ppmodel.extensions.ZeigerExtensions.*

/**
 * This class extends {@link Fstr_Abhaengigkeit}.
 */
class FstrAbhaengigkeitExtensions extends BasisObjektExtensions {

	/**
	 * @param fstr this Fstr_Abhaengigkeit
	 * 
	 * @return Schlüsselsperre, die überwacht sein muss, damit die Fstr gesichert ist
	 */
	def static Schluesselsperre schluesselsperre(
		Fstr_Abhaengigkeit abhaengigkeit
	) {
		return abhaengigkeit?.fstrAbhaengigkeitSsp?.IDSchluesselsperre.resolve(
			Schluesselsperre)
	}

	/**
	 * @param fstr this Fstr_Abhaengigkeit
	 * 
	 * @return the associated Fstr_Fahrweg
	 */
	def static Fstr_Fahrweg getFstrFahrweg(
		Fstr_Abhaengigkeit abhaengigkeit
	) {
		return abhaengigkeit?.IDFstrFahrweg.resolve(Fstr_Fahrweg)
	}

	/**
	 * @param fstr this Fstr_Abhaengigkeit
	 * 
	 * @return Bedienanzeigeelement, das wirksam sein muss, damit die Fstr gesichert ist
	 */
	def static Bedien_Anzeige_Element getBedienAnzeigeElement(
		Fstr_Abhaengigkeit abhaengigkeit
	) {
		return abhaengigkeit.IDBedienAnzeigeElement.resolve(
			Bedien_Anzeige_Element)
	}
}
