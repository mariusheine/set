/**
 * Copyright (c) 2017 DB Netz AG and others.
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.ppmodel.extensions

import java.nio.file.Path
import java.nio.file.Paths
import java.util.Collections
import java.util.GregorianCalendar
import java.util.List
import java.util.Optional
import java.util.Set
import javax.xml.datatype.DatatypeConfigurationException
import javax.xml.datatype.DatatypeFactory
import javax.xml.datatype.XMLGregorianCalendar
import org.eclipse.emf.common.util.Diagnostic
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.Diagnostician
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.edit.command.SetCommand
import org.eclipse.emf.edit.domain.EditingDomain
import org.eclipse.set.basis.constants.ContainerType
import org.eclipse.set.basis.constants.ExportType
import org.eclipse.set.basis.guid.Guid
import org.eclipse.set.core.services.Services
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.toolboxmodel.Basisobjekte.Anhang
import org.eclipse.set.toolboxmodel.Basisobjekte.BasisobjekteFactory
import org.eclipse.set.toolboxmodel.Basisobjekte.BasisobjektePackage
import org.eclipse.set.toolboxmodel.Basisobjekte.Identitaet_TypeClass
import org.eclipse.set.toolboxmodel.PlanPro.Akteur_Allg_AttributeGroup
import org.eclipse.set.toolboxmodel.PlanPro.Akteur_Zuordnung
import org.eclipse.set.toolboxmodel.PlanPro.DocumentRoot
import org.eclipse.set.toolboxmodel.PlanPro.ENUMPlanungEArt
import org.eclipse.set.toolboxmodel.PlanPro.ENUMPlanungPhase
import org.eclipse.set.toolboxmodel.PlanPro.Organisation
import org.eclipse.set.toolboxmodel.PlanPro.PlanProFactory
import org.eclipse.set.toolboxmodel.PlanPro.PlanProPackage
import org.eclipse.set.toolboxmodel.PlanPro.PlanPro_Schnittstelle
import org.eclipse.set.toolboxmodel.PlanPro.Planung_E_Allg_AttributeGroup
import org.eclipse.set.toolboxmodel.PlanPro.Planung_Gruppe
import org.eclipse.set.toolboxmodel.PlanPro.Planung_Projekt
import org.eclipse.set.utils.ToolboxConfiguration
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static extension org.eclipse.set.ppmodel.extensions.EObjectExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.PlanungEinzelExtensions.*
import static extension org.eclipse.set.ppmodel.extensions.PlanungProjektExtensions.*
import static extension org.eclipse.set.utils.StringExtensions.*

/**
 * Extensions for {@link PlanPro_Schnittstelle}.
 * 
 * @author Schaefer
 */
class PlanProSchnittstelleExtensions {

	static final Logger logger = LoggerFactory.getLogger(
		typeof(PlanProSchnittstelleExtensions));

	/**
	 * @param schnittstelle this PlanPro Schnittstelle
	 * 
	 * @return whether this Schnittstelle is a planning
	 */
	static def boolean isPlanning(PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle !== null &&
			schnittstelle.LSTPlanungProjekt !== null
	}

	/**
	 * Perform some corrections for the given PlanPro Schnittstelle.
	 * 
	 * @param schnittstelle this PlanPro Schnittstelle
	 * @return whether fixes have been applied
	 */
	static def void fix(PlanPro_Schnittstelle schnittstelle) {
		if (schnittstelle.planning) {
			schnittstelle.fixGuids
		}
	}

	/**
	 * Fills default values for the given PlanPro Schnittstelle's Objektmanagement if required.
	 * 
	 * @param schnittstelle this PlanPro Schnittstelle
	 * @return whether fixes have been applied
	 */
	static def boolean fixManagementDefaults(
		PlanPro_Schnittstelle schnittstelle) {
		val objman = schnittstelle?.LSTPlanung?.objektmanagement
		val requiresDefaults = objman.containsUnfilledValues
		if (requiresDefaults)
			objman.fillDefaults
		return requiresDefaults
	}

	static def boolean containsMissingLSTValues(
		PlanPro_Schnittstelle schnittstelle) {
		val objman = schnittstelle?.LSTPlanung?.objektmanagement
		val requiresDefaults = objman.containsUnfilledValues
		if (requiresDefaults)
			objman.fillDefaults
		return requiresDefaults
	}

	/**
	 * Fills default values for the given PlanPro Schnittstelle if required.
	 * 
	 * @param schnittstelle this PlanPro Schnittstelle
	 */
	static def void fixDefaults(PlanPro_Schnittstelle schnittstelle) {
		schnittstelle.fillDefaults
	}

	/**
	 * @param schnittstelle this PlanPro Schnittstelle
	 * @param container the wanted container
	 * 
	 * @return the specified container
	 */
	static def MultiContainer_AttributeGroup getContainer(
		PlanPro_Schnittstelle schnittstelle,
		ContainerType container) throws IllegalArgumentException {
		switch (container) {
			case INITIAL: {
				val projects = schnittstelle.LSTPlanungGruppe
				if (projects.isPresent) {
					val containers = projects.get.map [
						LSTPlanungEinzel?.LSTZustandStart?.container
					]
					return new MultiContainer_AttributeGroup(containers)
				}
				return null
			}
			case FINAL: {
				val projects = schnittstelle.LSTPlanungGruppe
				if (projects.isPresent) {
					val containers = projects.get.map [
						LSTPlanungEinzel?.LSTZustandZiel?.container
					]
					return new MultiContainer_AttributeGroup(containers)
				}
				return null
			}
			case SINGLE: {
				val singleContainer = schnittstelle?.LSTZustand?.container
				if (singleContainer !== null)
					return new MultiContainer_AttributeGroup(
						schnittstelle?.LSTZustand?.container);
				return null
			}
		}
	}

	/**
	 * @param schnittstelle this PlanPro Schnittstelle
	 * 
	 * @return the document root or <code>null</code> if this Schnittstelle is
	 * not contained within a document root
	 */
	static def DocumentRoot getDocumentRoot(
		PlanPro_Schnittstelle schnittstelle) {
		val container = schnittstelle.eContainer
		if (container instanceof DocumentRoot) {
			return container
		}
		return null
	}

	/**
	 * @param schnittstelle this PlanPro Schnittstelle
	 * 
	 * @return die Planung allgemein
	 */
	static def Planung_E_Allg_AttributeGroup getPlanungAllgemein(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEAllg
	}

	/**
	 * Copy meta data from this Schnittstelle to the destination Schnittstelle.
	 * 
	 * @param schnittstelle this PlanPro Schnittstelle
	 * @param destination the destination PlanPro Schnittstelle
	 */
	static def void copyMetaData(
		PlanPro_Schnittstelle schnittstelle,
		PlanPro_Schnittstelle destination
	) {
		val copy = EcoreUtil.copy(schnittstelle)
		destination.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
			anhangErlaeuterungsbericht.addAll(
				copy.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
					anhangErlaeuterungsbericht
			)
		destination.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
			anhangMaterialBesonders.addAll(
				copy.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
					anhangMaterialBesonders
			)
		destination.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.anhangVzG.
			addAll(
				copy.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.anhangVzG
			)
		destination.LSTPlanungProjekt.planungGruppe.
			LSTPlanungEinzel.planungEAllg = copy.LSTPlanungProjekt.
			planungGruppe.LSTPlanungEinzel.planungEAllg
		destination.LSTPlanungProjekt.planungGruppe.
			LSTPlanungEinzel.planungEHandlung = copy.LSTPlanungProjekt.
			planungGruppe.LSTPlanungEinzel.planungEHandlung
		destination.LSTPlanungProjekt.planungGruppe.planungGAllg = copy.
			LSTPlanungProjekt.planungGruppe.planungGAllg
		destination.LSTPlanungProjekt.
			planungGruppe.planungGFuehrendeStrecke = copy.LSTPlanungProjekt.
			planungGruppe.planungGFuehrendeStrecke
		destination.LSTPlanungProjekt.planungGruppe.planungGSchriftfeld = copy.
			LSTPlanungProjekt.planungGruppe.planungGSchriftfeld
		destination.LSTPlanungProjekt.planungPAllg = copy.LSTPlanungProjekt.
			planungPAllg

		// adapt meta data of destination to enforce a different file name
		val bauzustandKurzbezeichnung = destination?.LSTPlanungProjekt?.
			planungGruppe?.LSTPlanungEinzel?.planungEAllg?.
			bauzustandKurzbezeichnung?.wert
		if (bauzustandKurzbezeichnung !== null) {
			destination.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
				planungEAllg.
				bauzustandKurzbezeichnung.wert = '''«bauzustandKurzbezeichnung»_Gesamt'''
		}
	}

	/** 
	 * erzeugt eine leere PlanPro-Model-Instanz.
	 */
	static def PlanPro_Schnittstelle createEmptyModel() {
		val factory = PlanProFactory.eINSTANCE;
		val planPro_Schnittstelle = factory.createPlanPro_Schnittstelle();
		val allgemeineAttribute = factory.
			createPlanPro_Schnittstelle_Allg_AttributeGroup();
		val toolboxName = factory.createWerkzeug_Name_TypeClass();
		val toolboxVersion = factory.createWerkzeug_Version_TypeClass();
		val timestamp = factory.createErzeugung_Zeitstempel_TypeClass();
		allgemeineAttribute.setErzeugungZeitstempel(timestamp);
		allgemeineAttribute.setWerkzeugName(toolboxName);
		allgemeineAttribute.setWerkzeugVersion(toolboxVersion);

		planPro_Schnittstelle.setPlanProSchnittstelleAllg(allgemeineAttribute);

		val planungProject = factory.createPlanung_Projekt();
		planPro_Schnittstelle.setLSTPlanungProjekt(planungProject);

		val planungGruppe = factory.createPlanung_Gruppe();
		planungProject.setLSTPlanungGruppe(planungGruppe);

		val planungEinzel = factory.createPlanung_Einzel();
		planungGruppe.setLSTPlanungEinzel(planungEinzel);

		val schriftfeld = factory.createPlanung_G_Schriftfeld_AttributeGroup
		schriftfeld.planungsbuero = factory.createOrganisation
		planungGruppe.planungGSchriftfeld = schriftfeld

		val planungPAllg = factory.createPlanung_P_Allg_AttributeGroup
		val projektleiter = factory.createAkteur
		projektleiter.kontaktdaten = factory.createOrganisation
		projektleiter.akteurAllg = factory.createAkteur_Allg_AttributeGroup

		planungPAllg.projektleiter = projektleiter

		planungProject.planungPAllg = planungPAllg

		val fachdaten = factory.createFachdaten_AttributeGroup
		val ausgabeFachdaten = factory.createAusgabe_Fachdaten
		ausgabeFachdaten.fixGuids
		planungEinzel.IDAusgabeFachdaten = ausgabeFachdaten
		fachdaten.ausgabeFachdaten.add(ausgabeFachdaten)
		planungEinzel.LSTPlanung.fachdaten = fachdaten
		planungEinzel.planungEHandlung = factory.
			createPlanung_E_Handlung_AttributeGroup

		val zustandStart = factory.createLST_Zustand
		planungEinzel.ausgabeFachdaten.LSTZustandStart = zustandStart

		val planungAllgemein = factory.createPlanung_E_Allg_AttributeGroup();

		val bauzustand = factory.createBauzustand_Kurzbezeichnung_TypeClass();
		planungAllgemein.setBauzustandKurzbezeichnung(bauzustand);
		val lfdNummer = factory.createLaufende_Nummer_Ausgabe_TypeClass();

		planungAllgemein.setLaufendeNummerAusgabe(lfdNummer);
		val index = factory.createIndex_Ausgabe_TypeClass();
		planungAllgemein.setIndexAusgabe(index);
		planungEinzel.setPlanungEAllg(planungAllgemein);

		val containerStart = factory.createContainer_AttributeGroup();
		zustandStart.setContainer(containerStart);
		zustandStart.fixGuids

		val zustandZiel = factory.createLST_Zustand
		planungEinzel.ausgabeFachdaten.LSTZustandZiel = zustandZiel

		val containerZiel = factory.createContainer_AttributeGroup();
		zustandZiel.setContainer(containerZiel);
		zustandZiel.fixGuids
		planPro_Schnittstelle.fixDefaults
		return planPro_Schnittstelle
	}

	static def PlanPro_Schnittstelle readFrom(Resource resource) {
		val contents = resource.contents
		if (contents.empty) {
			return null
		}
		val root = contents.head
		if (root instanceof DocumentRoot) {
			return root.planProSchnittstelle
		}
		throw new IllegalArgumentException(
			"Ressource contains no PlanPro model with the requested version."
		);
	}

	static def Optional<Akteur_Allg_AttributeGroup> getProjektleiter(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungPAllg?.projektleiter?.
				akteurAllg
		)
	}

	static def Optional<Organisation> getFachplaner(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGSchriftfeld?.planungsbuero
		)
	}

	static def Optional<String> getBauphase(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.bauphase?.wert
		)
	}

	static def Optional<String> getBauzustandKurzbezeichnung(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.bauzustandKurzbezeichnung?.wert
		)
	}

	static def Optional<XMLGregorianCalendar> getDatumAbschlussEinzel(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.datumAbschlussEinzel?.wert
		)
	}

	static def Optional<String> getIndexAusgabe(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.indexAusgabe?.wert
		)
	}

	static def Optional<Boolean> getInformativ(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.informativ?.wert
		)
	}

	static def Optional<String> getLaufendeNummerAusgabe(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.laufendeNummerAusgabe?.wert
		)
	}

	static def Optional<ENUMPlanungEArt> getPlanungArt(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.planungEArt?.wert
		)
	}

	static def Optional<ENUMPlanungPhase> getPlanungPhase(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				planungEAllg?.planungPhase?.wert
		)
	}

	static def Optional<XMLGregorianCalendar> getDatumAbschlussGruppe(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.planungGAllg?.
				datumAbschlussGruppe?.wert
		)
	}

	static def Optional<String> getPlanProXSDVersion(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.planungGAllg?.
				planProXSDVersion?.wert
		)
	}

	static def Optional<String> getVerantwortlicheStelleDB(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.planungGAllg?.
				verantwortlicheStelleDB?.wert
		)
	}

	static def Optional<String> getStreckeAbschnitt(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGFuehrendeStrecke?.streckeAbschnitt?.wert
		)
	}

	static def Optional<String> getStreckeKm(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGFuehrendeStrecke?.streckeKm?.wert
		)
	}

	static def Optional<String> getBauabschnitt(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGSchriftfeld?.bauabschnitt?.wert
		)
	}

	static def Optional<String> getBezeichnungAnlage(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGSchriftfeld?.bezeichnungAnlage?.wert
		)
	}

	static def Optional<String> getBezeichnungPlanungGruppe(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGSchriftfeld?.bezeichnungPlanungGruppe?.wert
		)
	}

	static def Optional<String> getBezeichnungUnteranlage(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				planungGSchriftfeld?.bezeichnungUnteranlage?.wert
		)
	}

	static def Optional<String> getWerkzeugName(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.planProSchnittstelleAllg?.werkzeugName?.wert)
	}

	static def Optional<XMLGregorianCalendar> getErzeugungZeitstempel(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.planProSchnittstelleAllg?.erzeugungZeitstempel?.wert)
	}

	static def Optional<String> getWerkzeugVersion(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.planProSchnittstelleAllg?.werkzeugVersion?.wert)
	}

	static def Optional<String> getBezeichnungPlanungProjekt(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungPAllg?.
				bezeichnungPlanungProjekt?.wert)
	}

	static def Optional<XMLGregorianCalendar> getDatumAbschlussProjekt(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungPAllg?.
				datumAbschlussProjekt?.wert)
	}

	static def Optional<String> getProjektNummer(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungPAllg?.projektNummer?.wert)
	}

	static def Optional<String> getIdentitaet(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(schnittstelle?.identitaet?.wert)
	}
	
	static def Optional<String> getLSTPlanungEinzelIdentitaet(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.LSTPlanungEinzel?.
				identitaet?.wert)
	}

	static def Optional<String> getLSTPlanungGruppeIdentitaet(
		PlanPro_Schnittstelle schnittstelle) {
		val wert = schnittstelle?.LSTPlanungProjekt?.planungGruppe?.identitaet?.
			wert
		return Optional.ofNullable(wert)
	}
	
	static def Optional<Iterable<Planung_Gruppe>> getLSTPlanungGruppe(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(schnittstelle?.LSTPlanung?.objektmanagement?.LSTPlanungProjekt?.map [
			LSTPlanungGruppe
		]?.flatten)
	}

	static def Optional<String> getLSTPlanungProjektIdentitaet(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.identitaet?.wert)
	}

	static def Optional<String> getLSTZustandInformationIdentitaet(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(schnittstelle?.LSTZustand?.identitaet?.wert)
	}

	static def List<Akteur_Zuordnung> getPlanungAbnahme(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEAbnahme ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungErstellung(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEErstellung ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungFreigabe(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEFreigabe ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungGenehmigung(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEGenehmigung ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungGleichstellung(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEGleichstellung ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungPruefung(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEPruefung ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungQualitaetspruefung(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEQualitaetspruefung ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungSonstige(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungESonstige ?:
			Collections.emptyList
	}

	static def List<Akteur_Zuordnung> getPlanungUebernahme(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
			LSTPlanungEinzel?.planungEHandlung?.planungEUebernahme ?:
			Collections.emptyList
	}

	static def Optional<String> getFuehrendeOertlichkeit(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.LSTPlanungProjekt?.planungGruppe?.
				fuehrendeOertlichkeit?.wert)
	}

	static def Optional<String> getBemerkung(
		PlanPro_Schnittstelle schnittstelle) {
		return Optional.ofNullable(
			schnittstelle?.planProSchnittstelleAllg?.bemerkung?.wert)
	}

	static def boolean hasHandlung(PlanPro_Schnittstelle schnittstelle) {
		return !schnittstelle.planungAbnahme.empty ||
			!schnittstelle.planungErstellung.empty ||
			!schnittstelle.planungFreigabe.empty ||
			!schnittstelle.planungGenehmigung.empty ||
			!schnittstelle.planungGleichstellung.empty ||
			!schnittstelle.planungPruefung.empty ||
			!schnittstelle.planungQualitaetspruefung.empty ||
			!schnittstelle.planungUebernahme.empty ||
			!schnittstelle.planungSonstige.empty
	}

	/**
	 * Update tool name, version and time stamp.
	 * 
	 * @param schnittstelle the PlanPro Schnittstelle
	 * @param applicationName the application name
	 */
	static def void updateErzeugung(
		PlanPro_Schnittstelle schnittstelle,
		String applicationName,
		EditingDomain domain
	) {
		try {
			var cmd = SetCommand.create(
				domain,
				schnittstelle.planProSchnittstelleAllg.werkzeugName,
				PlanProPackage.eINSTANCE.werkzeug_Name_TypeClass_Wert,
				applicationName
			)
			domain.commandStack.execute(cmd)

			cmd = SetCommand.create(
				domain,
				schnittstelle.planProSchnittstelleAllg.werkzeugVersion,
				PlanProPackage.eINSTANCE.werkzeug_Version_TypeClass_Wert,
				ToolboxConfiguration.toolboxVersion.shortVersion
			)
			domain.commandStack.execute(cmd)

			cmd = SetCommand.create(
				domain,
				schnittstelle.planProSchnittstelleAllg.erzeugungZeitstempel,
				PlanProPackage.eINSTANCE.erzeugung_Zeitstempel_TypeClass_Wert,
				DatatypeFactory.newInstance.
					newXMLGregorianCalendar(new GregorianCalendar)
			)
			domain.commandStack.execute(cmd)
		} catch (DatatypeConfigurationException e) {
			throw new RuntimeException(e)
		}
	}

	/**
	 * @param schnittstelle the PlanPro Schnittstelle
	 * @param directory the directory
	 * 
	 * @return the path derived from the model and the given directory
	 */
	static def Path getDerivedPath(
		PlanPro_Schnittstelle schnittstelle,
		String directory,
		String fileExtension,
		ExportType exportType
	) {
		// derive raw filename
		val oertlichkeit = schnittstelle.fuehrendeOertlichkeit.orElse(
			"(oertlichkeit)")
		val index = schnittstelle.indexAusgabe.orElse("(index)")
		val lfdNummer = schnittstelle.laufendeNummerAusgabe.orElse(
			"(lfdNummer)")
		val bauzustand = schnittstelle.bauzustandKurzbezeichnung.orElse(
			"(bauzustand)"
		)

		var String filename
		if (exportType === ExportType.INVENTORY_RECORDS) {
			filename = '''«oertlichkeit»_«index»_«lfdNummer»_B_«bauzustand».«fileExtension»'''
		} else {
			filename = '''«oertlichkeit»_«index»_«lfdNummer»_«bauzustand».«fileExtension»'''
		}

		// revise filename		
		filename = filename.replaceAll("\\*", "");
		filename = filename.replaceAll("\\?", "");
		filename = filename.replaceAll(" ", "_");
		filename = filename.replaceAll("/", "-");
		filename = filename.replaceAll("\\\\", "-");
		filename = filename.replaceAll("\\|", "-");
		filename = filename.replaceAll(":", "-");
		filename = filename.replaceAll("<", "(");
		filename = filename.replaceAll(">", ")");

		return Paths.get(directory, filename);
	}

	static def Set<String> getGuids(PlanPro_Schnittstelle schnittstelle,
		ContainerType containerType) {
		return schnittstelle.getContainer(containerType).urObjekt.map [
			identitaet.wert
		].toSet
	}

	/**
	 * Update a planning for the primary planning of a planning integration.
	 * This will update several attributes used to derive the path of the model.
	 * 
	 * @param schnittstelle the PlanPro Schnittstelle
	 */
	static def void updateForIntegrationCopy(
		PlanPro_Schnittstelle schnittstelle, EditingDomain domain) {
		schnittstelle.updateForImport(domain, true, true)

		// update Kurzbezeichnung Bauzustand
		val kurzbezeichnung = schnittstelle.bauzustandKurzbezeichnung.orElse("")
		val kurzbezeichnungShort1 = kurzbezeichnung.shortenBy(1)
		val kurzbezeichnungShort2 = kurzbezeichnung.shortenBy(2)
		val kurzbezeichnung_G = '''«kurzbezeichnung»_G'''
		val kurzbezeichnungShort1_G = '''«kurzbezeichnungShort1»_G'''
		val kurzbezeichnungShort2_G = '''«kurzbezeichnungShort2»_G'''
		val bauzustandKurzbezeichnung = schnittstelle.LSTPlanungProjekt.
			planungGruppe.LSTPlanungEinzel.planungEAllg.
			bauzustandKurzbezeichnung
		bauzustandKurzbezeichnung.wert = kurzbezeichnung_G
		var Diagnostic diagnostic = Diagnostician.INSTANCE.validate(
			bauzustandKurzbezeichnung);
		if (diagnostic.getSeverity() != Diagnostic.OK) {
			bauzustandKurzbezeichnung.wert = kurzbezeichnungShort1_G
			diagnostic = Diagnostician.INSTANCE.validate(
				bauzustandKurzbezeichnung);
			if (diagnostic.getSeverity() != Diagnostic.OK) {
				bauzustandKurzbezeichnung.wert = kurzbezeichnungShort2_G
			}
		}
	}

	/**
	 * Update a planning for the primary planning of a planning import. This
	 * will update several attributes used to derive the path of the model.
	 * 
	 * @param schnittstelle the PlanPro Schnittstelle
	 * @param updateInitial whether to update the initial state guid
	 * @param updateFinal whether to update the final state guid
	 */
	static def void updateForImport(
		PlanPro_Schnittstelle schnittstelle,
		EditingDomain domain,
		boolean updateInitial,
		boolean updateFinal
	) {
		// increase Ausgabe Nummer
		val lfdNrStr = schnittstelle.laufendeNummerAusgabe.orElse("0")
		var lfdNrInt = 0
		try {
			lfdNrInt = Integer.parseInt(lfdNrStr)
		} catch (NumberFormatException e) {
			logger.error(
				'''LaufendeNummerAusgabe=«lfdNrStr» is no number. Zero is assumed for updateForImport.'''
			)
		}
		lfdNrInt++
		val setLaufendeNummer = SetCommand.create(
			domain,
			schnittstelle.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
				planungEAllg.laufendeNummerAusgabe,
			PlanProPackage.eINSTANCE.laufende_Nummer_Ausgabe_TypeClass_Wert,
			String.format("%02d", lfdNrInt)
		)
		domain.commandStack.execute(setLaufendeNummer)

		// new GUIDs
		val setPlanungProjektGuid = SetCommand.create(
			domain,
			schnittstelle.LSTPlanungProjekt.identitaet,
			BasisobjektePackage.eINSTANCE.identitaet_TypeClass_Wert,
			Guid.create.toString
		)
		domain.commandStack.execute(setPlanungProjektGuid)
		val setPlanungGruppeGuid = SetCommand.create(
			domain,
			schnittstelle.LSTPlanungProjekt.planungGruppe.identitaet,
			BasisobjektePackage.eINSTANCE.identitaet_TypeClass_Wert,
			Guid.create.toString
		)
		domain.commandStack.execute(setPlanungGruppeGuid)
		val setPlanungEinzelGuid = SetCommand.create(
			domain,
			schnittstelle.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
				identitaet,
			BasisobjektePackage.eINSTANCE.identitaet_TypeClass_Wert,
			Guid.create.toString
		)
		domain.commandStack.execute(setPlanungEinzelGuid)

		if (updateInitial) {
			val setStartGuid = SetCommand.create(
				domain,
				schnittstelle.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
					LSTZustandStart.identitaet,
				BasisobjektePackage.eINSTANCE.identitaet_TypeClass_Wert,
				Guid.create.toString
			)
			domain.commandStack.execute(setStartGuid)
		}
		if (updateFinal) {
			val setFinalGuid = SetCommand.create(
				domain,
				schnittstelle.LSTPlanungProjekt.planungGruppe.LSTPlanungEinzel.
					LSTZustandZiel.identitaet,
				BasisobjektePackage.eINSTANCE.identitaet_TypeClass_Wert,
				Guid.create.toString
			)
			domain.commandStack.execute(setFinalGuid)
		}
	}

	/**
	 * @param schnittstelle the PlanPro Schnittstelle
	 * 
	 * @return the (via PlanningAccessService) defined LST Planung Projekt of the Schnittstelle
	 */
	static def Planung_Projekt LSTPlanungProjekt(
		PlanPro_Schnittstelle schnittstelle
	) {
		// "1.9 update" toolbox currently supports only a single project
		return Services.planningAccessService.
			getLSTPlanungProjekt(schnittstelle)
	}

	/**
	 * Replace the first Planung Projekt for the given PlanPro Schnittstelle
	 * with the given Planung Projekt.
	 *  
	 * @param schnittstelle the PlanPro Schnittstelle
	 * @param planungProject the Planung Projekt
	 */
	static def void setLSTPlanungProjekt(
		PlanPro_Schnittstelle schnittstelle,
		Planung_Projekt planungProject
	) {
		Services.planningAccessService.setLSTPlanungProjekt(schnittstelle,
			planungProject);
	}

	private static def void fixGuids(PlanPro_Schnittstelle schnittstelle) {
		schnittstelle.LSTPlanung.objektmanagement.eAllContents.forEach [
			fixGuids
		]
	}

	private static def void fixGuids(EObject element) {
		// find containment reference of type Identitaet_TypeClass
		val idContainments = element.eClass.EAllContainments.filter [
			EType.instanceClass == typeof(Identitaet_TypeClass)
		]
		if (idContainments.empty) {
			return
		}
		if (idContainments.size > 1) {
			throw new RuntimeException('''size=«idContainments.size»''')
		}
		val idRef = idContainments.get(0)

		// get the value of the reference
		var Identitaet_TypeClass value = element.eGet(
			idRef) as Identitaet_TypeClass

		// set the value if it is null
		if (value === null) {
			value = BasisobjekteFactory.eINSTANCE.createIdentitaet_TypeClass
			element.eSet(idRef, value)
		}

		// set the wert if it is null
		if (value.wert === null) {
			value.wert = Guid.create.toString
		}
	}

	/**
	 * @param this schnittstelle
	 * @return  list of attachements within the schnittstelle 
	 */
	static def List<Anhang> getAttachments(
		PlanPro_Schnittstelle schnittstelle) {
		return schnittstelle.eAllContents.filter(Anhang).toList
	}
}
