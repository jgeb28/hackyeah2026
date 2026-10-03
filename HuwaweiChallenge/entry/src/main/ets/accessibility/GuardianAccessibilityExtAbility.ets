/**
 * GuardianAccessibilityExtAbility
 * ---------------------------------------------------------------------------
 * The ingestion half of the trigger (DESIGN.md §6). This extension observes the
 * messaging app via accessibility events and, **whenever text is rendered**,
 * flattens the visible element tree and hands it to TriggerEngine.
 *
 * There is no continuous polling: the OS calls `onAccessibilityEvent`, we filter
 * to the target bundle, read the current window root, and fire one scan. The
 * extension holds no UI; the verdict is logged (and later routed to AlertService).
 *
 * NOTE: the user must enable this service in Settings > Accessibility. Third-
 * party services are not auto-enabled.
 */
import {
  AccessibilityExtensionAbility,
  AccessibilityElement,
  AccessibilityEvent
} from '@kit.AccessibilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TriggerEngine, TARGET_BUNDLE } from '../trigger/TriggerEngine';
import { TriggerSource } from '../trigger/TriggerTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianAX';

/** Max characters sent to the classifier (bound inference cost, design §6). */
const MAX_TEXT_CHARS: number = 2000;

export default class GuardianAccessibilityExtAbility extends AccessibilityExtensionAbility {
  onConnect(): void {
    hilog.info(DOMAIN, TAG, 'accessibility service connected');
  }

  onDisconnect(): void {
    hilog.info(DOMAIN, TAG, 'accessibility service disconnected');
  }

  onAccessibilityEvent(event: AccessibilityEvent): void {
    // Keep the callback cheap: read + scan are async, wired fire-and-forget.
    this.handleEvent(event).catch((err: Object) => {
      hilog.error(DOMAIN, TAG, `handleEvent failed: ${err}`);
    });
  }

  private async handleEvent(event: AccessibilityEvent): Promise<void> {
    const source: TriggerSource = this.toSource(event);
    try {
      const root: AccessibilityElement | null = await this.context.getWindowRootElement();
      if (root === null) {
        return;
      }

      // Per-app gate: only observe the messaging app (design §6).
      const bundle: string = await this.attr(root, 'bundleName');
      if (bundle !== TARGET_BUNDLE) {
        return;
      }

      const full: string = await this.flatten(root);
      const text: string = full.length > MAX_TEXT_CHARS ? full.substring(0, MAX_TEXT_CHARS) : full;
      if (text.length === 0) {
        return;
      }

      TriggerEngine.get().onTextRendered(bundle, text, source);
    } catch (err) {
      hilog.error(DOMAIN, TAG, `event handling failed: ${err}`);
    }
  }

  /** Map the raw accessibility event type onto our trigger sources (§6). */
  private toSource(event: AccessibilityEvent): TriggerSource {
    const type: string = `${event.eventType}`;
    if (type.includes('textUpdate')) {
      return TriggerSource.TEXT_UPDATE;
    }
    if (type.includes('page')) {
      return TriggerSource.PAGE_ACTIVE;
    }
    if (type.includes('scroll')) {
      return TriggerSource.SCROLL;
    }
    if (type.includes('notification')) {
      return TriggerSource.NOTIFICATION;
    }
    if (type.includes('window')) {
      return TriggerSource.WINDOW_UPDATE;
    }
    return TriggerSource.UNKNOWN;
  }

  /** Safely read a string attribute of an element. */
  private async attr(element: AccessibilityElement, name: 'text' | 'description' | 'bundleName'): Promise<string> {
    try {
      const value: string = await element.attributeValue(name);
      return typeof value === 'string' ? value : '';
    } catch (err) {
      return '';
    }
  }

  /** Flatten the element tree into one normalized string (§6). */
  private async flatten(element: AccessibilityElement): Promise<string> {
    const parts: string[] = [];

    const text: string = await this.attr(element, 'text');
    if (text.length > 0) {
      parts.push(text);
    }
    const description: string = await this.attr(element, 'description');
    if (description.length > 0) {
      parts.push(description);
    }

    let children: Array<AccessibilityElement> = [];
    try {
      const value: Array<AccessibilityElement> = await element.attributeValue('children');
      if (value !== undefined && value !== null) {
        children = value;
      }
    } catch (err) {
      children = [];
    }

    for (const child of children) {
      const childText: string = await this.flatten(child);
      if (childText.length > 0) {
        parts.push(childText);
      }
    }

    return parts.join(' ').trim();
  }
}
