/**
 * Copyright (c) 2022 DB Netz AG and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v2.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v20.html
 */
package org.eclipse.set.feature.table.pt1

import java.util.Comparator
import org.eclipse.emf.common.util.Enumerator
import org.eclipse.set.basis.constants.ToolboxConstants
import org.eclipse.set.core.services.enumtranslation.EnumTranslationService
import org.eclipse.set.ppmodel.extensions.container.MultiContainer_AttributeGroup
import org.eclipse.set.utils.table.AbstractTableModelTransformator
 
abstract class AbstractPlanPro2TableModelTransformator extends AbstractTableModelTransformator<MultiContainer_AttributeGroup> {
	protected val FootnoteTransformation footnoteTransformation = new FootnoteTransformation()
	protected val EnumTranslationService enumTranslationService

	/**
	 * Compares mixed strings groupwise.
	 */
	protected static val Comparator<String> MIXED_STRING_COMPARATOR = ToolboxConstants.
		LST_OBJECT_NAME_COMPARATOR
		
	new(EnumTranslationService enumTranslationService) {
		super()
		this.enumTranslationService = enumTranslationService
	}

	/**
	 * Translates the enum via the enum translation service.
	 * 
	 * @param enumerator the enumerator
	 * 
	 * @return the translation or <code>null</code>, if the enumerator is <code>null</code>
	 */
	def String translate(Enumerator enumerator) {
		if (enumerator === null) {
			return null
		}
		return enumTranslationService.translate(enumerator).alternative
	}

	/**
	 * Translates the boolean via the enum translation service.
	 * 
	 * @param value the value
	 * 
	 * @return the translation or <code>null</code>, if the value is <code>null</code>
	 */
	def String translate(Boolean value) {
		if (value === null) {
			return null
		}
		return enumTranslationService.translate(value).alternative
	}
}