import * as Brownfield from 'expo-brownfield';
import { useEffect, useRef, useState } from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  useColorScheme,
  View,
} from 'react-native';
import Animated, { interpolate, useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import type { TextInputInstance } from 'react-native';

type NoteCardProps = {
  initialNote: string;
  noteSessionID: string;
  fontStyle: string;
};

export default function NoteCard({ initialNote, noteSessionID, fontStyle }: NoteCardProps) {
  const [note, setNote] = useState(initialNote);
  const [editing, setEditing] = useState(false);
  const editingRef = useRef(false);
  const noteRef = useRef(initialNote);
  const inputRef = useRef<TextInputInstance>(null);
  const progress = useSharedValue(0);
  const dark = useColorScheme() === 'dark';
  const ink = dark ? '#B6D4C0' : '#004225';
  const card = dark ? '#222521' : '#FFFFFF';
  const border = dark ? '#3A3D3A' : '#E7E0E7';
  const fontFamily = fontStyle === 'handwritten' ? 'Caveat' : fontStyle === 'serif' ? 'Georgia' : undefined;
  const fontSize = fontStyle === 'handwritten' ? 22 : 18;

  useEffect(() => {
    if (editing) inputRef.current?.focus();
  }, [editing]);

  const animatedCardStyle = useAnimatedStyle(() => ({
    borderRadius: interpolate(progress.get(), [0, 1], [20, 24]),
    transform: [
      { translateY: interpolate(progress.get(), [0, 1], [0, -2]) },
      { rotate: `${interpolate(progress.get(), [0, 1], [-1.5, 0])}deg` },
      { scale: interpolate(progress.get(), [0, 1], [0.985, 1]) },
    ],
  }));

  function send(type: string, text = noteRef.current) {
    Brownfield.sendMessage({ type, sessionID: noteSessionID, text });
  }

  function startEditing() {
    if (editingRef.current) return;
    editingRef.current = true;
    setEditing(true);
    progress.set(withSpring(1, { duration: 380, dampingRatio: 0.86 }));
    send('artworkNote:focus');
  }

  function finishEditing() {
    if (!editingRef.current) return;
    editingRef.current = false;
    setEditing(false);
    progress.set(withSpring(0, { duration: 380, dampingRatio: 0.86 }));
    send('artworkNote:blur');
  }

  return (
    <View style={styles.root}>
      <Animated.View
        style={[
          styles.card,
          { backgroundColor: card, borderColor: border },
          animatedCardStyle,
        ]}
      >
        {editing ? (
          <>
            <TextInput
              ref={inputRef}
              accessibilityLabel="Memory description"
              value={note}
              onChangeText={(text) => {
                noteRef.current = text;
                setNote(text);
                send('artworkNote:change', text);
              }}
              onBlur={finishEditing}
              onSubmitEditing={finishEditing}
              multiline
              scrollEnabled
              returnKeyType="done"
              submitBehavior="blurAndSubmit"
              placeholder="What do you want to remember?"
              placeholderTextColor={dark ? '#789282' : '#809F8D'}
              selectionColor={ink}
              style={[styles.input, { color: ink, fontFamily, fontSize }]}
            />
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Done editing memory description"
              onPress={() => {
                inputRef.current?.blur();
                finishEditing();
              }}
              style={styles.doneButton}
            >
              <Text style={[styles.doneText, { color: ink }]}>Done</Text>
            </Pressable>
          </>
        ) : (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={note ? 'Edit memory description' : 'Add memory description'}
            onPress={startEditing}
            style={styles.preview}
          >
            <Text
              numberOfLines={3}
              style={[
                styles.previewText,
                { color: note ? ink : dark ? '#789282' : '#809F8D', fontFamily, fontSize },
              ]}
            >
              {note || 'What do you want to remember?'}
            </Text>
          </Pressable>
        )}
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, paddingHorizontal: 4, backgroundColor: 'transparent' },
  card: {
    flex: 1,
    width: '100%',
    borderWidth: 1,
    shadowColor: '#000000',
    shadowOpacity: 0.10,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 5 },
    elevation: 5,
  },
  input: {
    flex: 1,
    marginHorizontal: 14,
    marginVertical: 11,
    padding: 0,
    textAlignVertical: 'top',
  },
  preview: { flex: 1, paddingHorizontal: 14, paddingVertical: 17 },
  previewText: { lineHeight: 25 },
  doneButton: {
    alignSelf: 'flex-end',
    minWidth: 54,
    minHeight: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
    marginBottom: 6,
  },
  doneText: { fontSize: 15, fontWeight: '600' },
});
