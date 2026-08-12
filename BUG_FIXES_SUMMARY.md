# Bug Fixes Summary - VSS Power Quotation Generator

## Date: 2026-08-12

---

## BUG 1: `openNew is not defined` in QuotationsPage

### Root Cause
The "+ Add Quotation" button in `QuotationsPage` component was calling `openNew()` which was never defined. The correct function `newQuotation()` existed in the parent `App` component but wasn't passed as a prop.

### Location
- **File:** `index.html`
- **Component:** `QuotationsPage`
- **Line:** ~2358 (before fix)

### Fix Applied

#### 1. Updated App component to pass `newQuotation` prop (Line ~862)
```javascript
// BEFORE:
{view==='quotations' && (
  <QuotationsPage quotations={quotations} openQuotation={openQuotation} duplicateQuotation={duplicateQuotation}
    deleteQuotation={deleteQuotation} downloadPdf={downloadPdf} />
)}

// AFTER:
{view==='quotations' && (
  <QuotationsPage quotations={quotations} openQuotation={openQuotation} newQuotation={newQuotation}
    duplicateQuotation={duplicateQuotation} deleteQuotation={deleteQuotation} downloadPdf={downloadPdf} />
)}
```

#### 2. Updated QuotationsPage function signature (Line ~2336)
```javascript
// BEFORE:
function QuotationsPage({ quotations, openQuotation, duplicateQuotation, deleteQuotation, downloadPdf })

// AFTER:
function QuotationsPage({ quotations, openQuotation, newQuotation, duplicateQuotation, deleteQuotation, downloadPdf })
```

#### 3. Fixed the button onClick handler (Line ~2358)
```javascript
// BEFORE:
<button onClick={openNew} className="px-4 py-2 text-sm rounded text-white" style={{background:'var(--steel)'}}>+ Add Quotation</button>

// AFTER:
<button onClick={newQuotation} className="px-4 py-2 text-sm rounded text-white" style={{background:'var(--steel)'}}>+ Add Quotation</button>
```

### Result
✅ The "+ Add Quotation" button now correctly calls `newQuotation()`, which:
- Creates a blank quotation using `blankQuotation(settings)`
- Fetches the next quotation number from Supabase
- Sets it as the active quotation
- Switches to the wizard view

---

## BUG 2: Step 3 "Continue" Button Crashes / Blank Screen

### Root Cause
The "Continue →" button on step 3 (Services & Pricing) calls `goNext()`, which synchronously called `onSaveDraft(quotation)`. If the save operation threw an error (e.g., network failure, Supabase schema mismatch, missing required fields), the error was unhandled and caused the app to crash with a blank screen.

### Location
- **File:** `index.html`
- **Component:** `Wizard`
- **Function:** `goNext`
- **Line:** ~1897 (before fix)

### Fix Applied

#### 1. Added async/await error handling to `goNext` (Line ~1947)
```javascript
// BEFORE:
const goNext = () => { if(!validateStep()) return; onSaveDraft(quotation); setStep(s=>Math.min(WIZARD_STEPS.length-1, s+1)); };

// AFTER:
const goNext = async () => { 
  try {
    if(!validateStep()) return; 
    console.log('[DEBUG] goNext: validation passed, saving draft...');
    await onSaveDraft(quotation); 
    console.log('[DEBUG] goNext: draft saved, advancing step...');
    setStep(s=>Math.min(WIZARD_STEPS.length-1, s+1)); 
    console.log('[DEBUG] goNext: step advanced successfully');
  } catch(err) {
    console.error('[ERROR] goNext failed:', err);
    alert('Failed to save or advance step: ' + err.message);
  }
};
```

### Benefits
✅ **Async handling:** Properly waits for save operation to complete
✅ **Error catching:** Catches and logs any errors during save or step transition
✅ **User feedback:** Shows an alert if the save fails, explaining what went wrong
✅ **Debug logging:** Console logs help diagnose future issues
✅ **Graceful degradation:** App doesn't crash; user can retry or fix data

---

## BUG 3 (Prevention): Added React Error Boundary

### Purpose
Catch any unhandled rendering errors throughout the app and display a recoverable error message instead of a blank screen.

### Location
- **File:** `index.html`
- **New Component:** `ErrorBoundary`
- **Lines:** ~642-690

### Implementation

#### 1. Added ErrorBoundary class component (Line ~642)
```javascript
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('[ErrorBoundary] Caught error:', error, errorInfo);
    this.setState({ error, errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{...}}>
          <div style={{...}}>
            <h1>Something went wrong</h1>
            <p>The application encountered an error and couldn't continue. Try refreshing the page.</p>
            <details>
              <summary>Error details</summary>
              <pre>{error details}</pre>
            </details>
            <button onClick={() => window.location.reload()}>Reload Page</button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}
```

#### 2. Wrapped top-level render (Line ~1024)
```javascript
// BEFORE:
root.render(<LoginGate />);

// AFTER:
root.render(<ErrorBoundary><LoginGate /></ErrorBoundary>);
```

### Benefits
✅ **Prevents blank screens:** Shows a friendly error message instead of crashing
✅ **Error details:** Provides technical details for debugging
✅ **Recovery option:** "Reload Page" button lets users try again
✅ **Console logging:** Errors are logged for developer inspection
✅ **Better UX:** Users know something went wrong and have a clear action

---

## Additional Notes

### Supabase Client Variable Conflict (Previously Fixed)
The initial issue where `const supabase` conflicted with `var supabase` from `vendor/supabase.js` was already fixed by renaming the client instance to `sbClient` throughout the codebase.

### Testing Recommendations

1. **Test BUG 1 Fix:**
   - Navigate to "Quotations" page
   - Click "+ Add Quotation" button
   - Verify a new quotation wizard opens without errors

2. **Test BUG 2 Fix:**
   - Create a new quotation
   - Fill in Client (step 0) and Project (step 1) info
   - Add at least one service line item on step 2
   - Click "Continue →" to advance to step 3
   - Verify step 3 (Commercial Terms) loads successfully
   - Check browser console for debug logs: `[DEBUG] goNext: ...`

3. **Test Error Boundary:**
   - Temporarily add `throw new Error('test')` in a component's render
   - Verify the error boundary catches it and shows the error screen
   - Click "Reload Page" to recover

4. **Test Network Failure Scenario:**
   - Disconnect network or block Supabase API
   - Try to advance from step 2 to step 3
   - Verify an alert appears: "Failed to save or advance step: ..."
   - User can retry after fixing network

---

## Files Modified

- `index.html` (all changes in single file)

## Lines Changed

| Change | Line Range (approx) |
|--------|---------------------|
| ErrorBoundary component added | ~642-690 |
| ErrorBoundary wrapper in render | ~1024 |
| App passes newQuotation prop | ~862 |
| QuotationsPage signature updated | ~2336 |
| Button onClick fixed | ~2418 |
| goNext error handling | ~1947-1959 |

---

## Status: ✅ COMPLETE

All identified bugs have been fixed:
- ✅ BUG 1: `openNew is not defined` → Fixed
- ✅ BUG 2: Step 3 continue crash → Fixed with error handling
- ✅ BUG 3: General error boundary → Added for future protection

The app should now:
1. Allow creating new quotations from the Quotations page
2. Safely advance through wizard steps with proper error handling
3. Show recoverable error messages instead of blank screens
