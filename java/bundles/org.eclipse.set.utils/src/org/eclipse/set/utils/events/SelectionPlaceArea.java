/**
 * Copyright (c) 2024 DB InfraGO AG and others
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v2.0 which is available at
 * https://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * 
 */
package org.eclipse.set.utils.events;

import java.util.Collections;
import java.util.Set;

import org.eclipse.set.basis.constants.ContainerType;
import org.eclipse.set.basis.constants.TableType;
import org.eclipse.set.model.planpro.Ansteuerung_Element.Stell_Bereich;

/**
 * Selected place areas was change
 * 
 * @author Truong
 */
public class SelectionPlaceArea implements ToolboxEvent {

	/**
	 * Helper class for define place area
	 * 
	 * @param areaName
	 *            the name of area
	 * @param area
	 *            the {@link Stell_Bereich}
	 * @param containerType
	 *            the {@link ContainerType}, which belong to this area
	 */
	public record PlaceAreaValue(String areaName, Stell_Bereich area,
			ContainerType containerType) {
	}

	private static final String TOPIC = "toolboxevents/stellbereich/selection"; //$NON-NLS-1$
	Set<PlaceAreaValue> areas;
	private final TableType tableType;

	/**
	 * @return the table type
	 */
	public TableType getTableType() {
		return tableType;
	}

	/**
	 * Default constructor
	 */
	public SelectionPlaceArea() {
		this.areas = null;
		this.tableType = null;

	}

	/**
	 * @param tableType
	 *            current tableType
	 * 
	 */
	public SelectionPlaceArea(final TableType tableType) {
		this(Collections.emptySet(), tableType);
	}

	/**
	 * Constructor
	 * 
	 * @param area
	 *            the {@link PlaceAreaValue}
	 * @param tableType
	 *            current tableType
	 */
	public SelectionPlaceArea(final PlaceAreaValue area,
			final TableType tableType) {
		this(Set.of(area), tableType);
	}

	/**
	 * Constructor
	 * 
	 * @param areas
	 *            the list of area
	 * @param tableType
	 *            current tableType
	 */
	public SelectionPlaceArea(final Set<PlaceAreaValue> areas,
			final TableType tableType) {
		this.areas = areas;
		this.tableType = tableType;
	}

	/**
	 * @return the place areas
	 */
	public Set<PlaceAreaValue> getPlaceAreas() {
		return areas;
	}

	@Override
	public String getTopic() {
		return TOPIC;
	}
}
