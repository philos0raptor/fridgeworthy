import { Image } from 'expo-image';
import * as Brownfield from 'expo-brownfield';
import { useCallback, useRef, useState } from 'react';
import { FlatList, Pressable, StyleSheet, View } from 'react-native';
import type { CellRendererProps } from '@react-native/virtualized-lists';
import Animated, {
  Extrapolation,
  interpolate,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
} from 'react-native-reanimated';
import type { SharedValue } from 'react-native-reanimated';
import NoteCard from './NoteCard';

type ArtworkImage = { id: string; uri: string };
type AppProps = {
  mode?: 'carousel' | 'note';
  images?: ArtworkImage[];
  allowsAddingPhoto?: boolean;
  initialNote?: string;
  noteSessionID?: string;
  fontStyle?: string;
};
type CarouselItem = ArtworkImage & { isAddCard?: boolean };

const ITEM_WIDTH = 120;
const AnimatedList = Animated.createAnimatedComponent(FlatList<CarouselItem>);

function Card({
  item,
  index,
  height,
  cardWidth,
  scrollOffset,
  onPress,
}: {
  item: CarouselItem;
  index: number;
  height: number;
  cardWidth: number;
  scrollOffset: SharedValue<number>;
  onPress: () => void;
}) {
  const animatedStyle = useAnimatedStyle(() => {
    const distance = (index * ITEM_WIDTH - scrollOffset.get()) / ITEM_WIDTH;
    const magnitude = Math.abs(distance);

    return {
      opacity: interpolate(magnitude, [0, 3, 4], [1, 1, 0], Extrapolation.CLAMP),
      transform: [
        { perspective: 900 },
        {
          translateX: -distance * (ITEM_WIDTH - cardWidth * 0.28),
        },
        {
          translateY: interpolate(magnitude, [0, 1, 2, 3], [0, 8, 14, 20], Extrapolation.CLAMP),
        },
        { scale: interpolate(magnitude, [0, 1, 2, 3], [1, 0.86, 0.75, 0.65], Extrapolation.CLAMP) },
        { rotate: `${interpolate(distance, [-3, -1, 0, 1, 3], [-15, -9, 0, 9, 15], Extrapolation.CLAMP)}deg` },
        { rotateY: `${interpolate(distance, [-2, -1, -0.5, 0, 0.5, 1, 2], [-10, -8, -20, 0, 20, 8, 10], Extrapolation.CLAMP)}deg` },
      ],
    };
  }, [cardWidth, index]);

  return (
    <Animated.View style={[styles.item, { height: height / 0.88 }, animatedStyle]}>
      <View style={[styles.cardShadow, { width: cardWidth, height }]}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={item.isAddCard ? 'Add another photo' : `Artwork photo ${index + 1}`}
          onPress={onPress}
          style={[styles.card, { width: cardWidth, height }]}
        >
          {item.isAddCard ? (
            <View style={[styles.addCard, { width: cardWidth, height }]}>
              <Image source={require('./assets/capture.png')} style={styles.addIcon} contentFit="contain" />
            </View>
          ) : (
            <Image
              source={{ uri: item.uri }}
              style={{ width: cardWidth, height }}
              contentFit="cover"
              cachePolicy="memory-disk"
            />
          )}
        </Pressable>
      </View>
    </Animated.View>
  );
}

function StackCell({
  children,
  index,
  style,
  onLayout,
  scrollOffset,
}: CellRendererProps<CarouselItem> & { scrollOffset: SharedValue<number> }) {
  const animatedStyle = useAnimatedStyle(() => ({
    zIndex: 100 - Math.abs(index - scrollOffset.get() / ITEM_WIDTH) * 10,
  }), [index]);

  return (
    <Animated.View onLayout={onLayout} style={[style, animatedStyle]}>
      {children}
    </Animated.View>
  );
}

function ArtworkCarousel({ images = [], allowsAddingPhoto = false }: AppProps) {
  const [viewport, setViewport] = useState({ width: 0, height: 0 });
  const listRef = useRef<FlatList<CarouselItem>>(null);
  const scrollOffset = useSharedValue(0);
  const onScroll = useAnimatedScrollHandler({
    onScroll: (event) => {
      scrollOffset.set(event.contentOffset.x);
    },
  });
  const items: CarouselItem[] = allowsAddingPhoto
    ? [...images, { id: 'add-photo', uri: '', isAddCard: true }]
    : images;
  const cardHeight = viewport.height * 0.88;
  const cardWidth = Math.min(250, cardHeight * 0.8);

  const renderItem = useCallback(
    ({ item, index }: { item: CarouselItem; index: number }) => (
      <Card
        item={item}
        index={index}
        height={cardHeight}
        cardWidth={cardWidth}
        scrollOffset={scrollOffset}
        onPress={() => {
          const selected = Math.round(scrollOffset.get() / ITEM_WIDTH);
          if (selected !== index) {
            listRef.current?.scrollToIndex({ index, animated: true });
          } else if (item.isAddCard) {
            Brownfield.sendMessage({ type: 'artworkCarousel:addPhoto' });
          }
        }}
      />
    ),
    [cardHeight, cardWidth, scrollOffset]
  );
  const renderCell = useCallback(
    (props: CellRendererProps<CarouselItem>) => <StackCell {...props} scrollOffset={scrollOffset} />,
    [scrollOffset]
  );

  return (
    <View
      style={styles.container}
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        setViewport((current) =>
          current.width === width && current.height === height ? current : { width, height }
        );
      }}
    >
      {viewport.width > 0 && viewport.height > 0 && (
        <AnimatedList
          ref={listRef}
          data={items}
          renderItem={renderItem}
          CellRendererComponent={renderCell}
          keyExtractor={(item) => item.id}
          horizontal
          decelerationRate="fast"
          snapToInterval={ITEM_WIDTH}
          disableIntervalMomentum
          showsHorizontalScrollIndicator={false}
          scrollEventThrottle={16}
          onScroll={onScroll}
          removeClippedSubviews={false}
          style={styles.transparent}
          contentContainerStyle={{
            alignItems: 'center',
            paddingHorizontal: Math.max(0, (viewport.width - ITEM_WIDTH) / 2),
          }}
          getItemLayout={(_, index) => ({ length: ITEM_WIDTH, offset: ITEM_WIDTH * index, index })}
        />
      )}
    </View>
  );
}

export default function App(props: AppProps) {
  if (props.mode === 'note') {
    return (
      <NoteCard
        initialNote={props.initialNote ?? ''}
        noteSessionID={props.noteSessionID ?? ''}
        fontStyle={props.fontStyle ?? 'rounded'}
      />
    );
  }

  return <ArtworkCarousel images={props.images} allowsAddingPhoto={props.allowsAddingPhoto} />;
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: 'transparent' },
  transparent: { backgroundColor: 'transparent' },
  item: {
    width: ITEM_WIDTH,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'visible',
  },
  cardShadow: {
    borderRadius: 20,
    shadowColor: '#281E12',
    shadowOpacity: 0.18,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 7 },
    elevation: 7,
  },
  card: {
    overflow: 'hidden',
    borderRadius: 20,
    backgroundColor: '#F6F1E8',
  },
  addCard: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#C9BBE8',
  },
  addIcon: { width: 88, height: 88 },
});
